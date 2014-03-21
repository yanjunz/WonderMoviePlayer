//
//  VideoGroup+Additions.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "VideoGroup+Additions.h"
#import "VideoChannelInfo.h"
#import "Video+Additions.h"
#import "VideoChannelInfo+Additions.h"
#import "NSString+Hash.h"

@implementation VideoGroup (Additions)

+ (instancetype)videoGroupWithVideoId:(NSString *)videoId
{
    return [self videoGroupWithVideoId:videoId inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (instancetype)videoGroupWithVideoId:(NSString *)videoId inContext:(NSManagedObjectContext *)context
{
    return [VideoGroup MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"videoId == %@", videoId] inContext:context];
}

+ (NSString *)unRecognizedVideoIdPrefix
{
    return @"_P_O_";
}

+ (NSString *)generateVideoIdForUnRecognizedWebURL:(NSString *)webURL
{
    return [[self unRecognizedVideoIdPrefix] stringByAppendingString:[webURL MD5]];
}

+ (BOOL)isVideoIdRecognized:(NSString *)videoId
{
    return ![videoId hasPrefix:[self unRecognizedVideoIdPrefix]];
}

+ (NSString *)srcDescription:(NSInteger)srcIndex
{
    /*
     1 = 搜狐
     2 = 爱奇艺
     3 = 腾讯视频
     4 = 乐视
     5 = 优酷
     6 = 土豆
     7 = 风行网
     8 = 电影网
     9 = PPTV
     10 = 迅雷看看
     11 = PPS
     12 = 酷6
     13 = 新浪
     14 = 快播
     15 = CNTV
     16 = 56
     */
    NSDictionary *dict = @{
                           @(1) : @"搜狐",
                           @(2) : @"爱奇艺",
                           @(3) : @"腾讯视频",
                           @(4) : @"乐视",
                           @(5) : @"优酷",
                           @(6) : @"土豆",
                           @(7) : @"风行网",
                           @(8) : @"电影网",
                           @(9) : @"PPTV",
                           @(10) : @"迅雷看看",
                           @(11) : @"PPS",
                           @(12) : @"酷6",
                           @(13) : @"新浪",
                           @(14) : @"快播",
                           @(15) : @"CNTV",
                           @(16) : @"56",
                           };
    NSString *desc = dict[@(srcIndex)];
    return desc;
}

+ (NSInteger)srcIndex:(NSString *)srcDescription
{
    NSDictionary *dict = @{
                           @(1) : @"搜狐",
                           @(2) : @"爱奇艺",
                           @(3) : @"腾讯视频",
                           @(4) : @"乐视",
                           @(5) : @"优酷",
                           @(6) : @"土豆",
                           @(7) : @"风行网",
                           @(8) : @"电影网",
                           @(9) : @"PPTV",
                           @(10) : @"迅雷看看",
                           @(11) : @"PPS",
                           @(12) : @"酷6",
                           @(13) : @"新浪",
                           @(14) : @"快播",
                           @(15) : @"CNTV",
                           @(16) : @"56",
                           };

    for (NSNumber *key in dict.allKeys) {
        if ([dict[key] isEqualToString:srcDescription]) {
            return [key intValue];
        }
    }
    return 0;
}

- (Video *)videoAtURL:(NSString *)URL
{
    VideoChannelInfo *videoChannelInfo = [VideoChannelInfo MR_findFirstByAttribute:@"url" withValue:URL inContext:self.managedObjectContext];
    return videoChannelInfo.video;
}

- (Video *)videoAtSetNum:(NSNumber *)setNum
{
    /**
     * NOTE:
     * The principle of wirting CoreData code
     * If the function may be used for update, make sure to pass MOC as parameter. Otherwise just use it for reading
     **/
    return [Video MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"videoGroup == %@ AND setNum == %d", self, [setNum intValue]] inContext:self.managedObjectContext];
}

- (NSArray *)sortedVideos:(BOOL)ascending
{
    return [self.videos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"setNum" ascending:ascending]]];
}

- (BOOL)isValidDrama
{
    return self.showType.intValue != VideoGroupShowTypeNone;
}

- (BOOL)isRecognized
{
    return ![self.videoId hasPrefix:[VideoGroup unRecognizedVideoIdPrefix]] && (self.totalCount.intValue != 0 || self.maxId.intValue != 0) && ![self isValidDrama];
}

+ (NSString *)temporaryDisplayName
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyyMMddhhmmss";
    return [NSString stringWithFormat:@"视频 %@",  [df stringFromDate:[NSDate date]]];
}

- (NSString *)displayNameForSetNum:(NSNumber *)setNum
{
    if ([self isValidDrama]) {
        return [NSString stringWithFormat:@"%@ 第%d集", self.videoName, [setNum intValue]];
    }
    else if (self.videoName.length > 0) {
        return self.videoName;
    }
    else {
        return [VideoGroup temporaryDisplayName];
    }
}

- (NSArray *)downloadedVideos
{
    NSMutableArray *downloadArray = [NSMutableArray array];
    for (Video *video in self.videos) {
//        NSLog(@"%@, %@, %@", video.setNum, video.path, video.createTime);
        /**
         * 1. downloading
         * 2. downloaded
         * 3. downloaded but task removed
         */
        if ((video.createTime.integerValue > 0 && video.completedTime.integerValue == 0) ||
            (video.createTime.integerValue > 0 && video.completedTime.integerValue > video.createTime.integerValue && video.path.length > 0) ||
            (video.createTime.integerValue == 0 && video.completedTime.integerValue == 0 && video.path.length > 0)) {
            [downloadArray addObject:video];
        }
    }
    return downloadArray;
    
    // FIXME: don't work sometime
//    return [Video MR_findAllSortedBy:@"setNum" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"path.length > 0 AND videoGroup == %@", self]];
}

- (void)checkDownloadedVideosExist
{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        VideoGroup *videoGroupInContext = [self MR_inContext:localContext];
        
        NSArray *downloadVideos = [videoGroupInContext downloadedVideos];
        for (Video *video in downloadVideos) {
            /**
             * Path is valid in following cases:
             * 1. has path && in downloading && file not existed
             * 2. has path && downloaded && file existed
             * 3. has path && download task is removed && file existed
             **/
            if (video.path.length > 0) {
                BOOL fileShouldBeExist = NO;
                if (video.createTime.integerValue > 0 && video.completedTime.integerValue == 0) {
                    fileShouldBeExist = NO;
                }
                else if (video.createTime.integerValue > 0 && video.completedTime.integerValue > video.createTime.integerValue) {
                    fileShouldBeExist = YES;
                }
                else if (video.createTime.integerValue == 0 && video.completedTime.integerValue == 0) {
                    fileShouldBeExist = YES;
                }
            
                if (fileShouldBeExist) {
//                    NSString *downloadingPath = [NSString stringWithFormat:@"%@/.%@", [video.path stringByDeletingLastPathComponent], [video.path lastPathComponent]];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:video.path]
//                        &&![[NSFileManager defaultManager] fileExistsAtPath:downloadingPath]
                        ) {
                        video.path = nil;
                        video.completedTime = nil;
                        video.createTime = nil;
                    }
                }
            }
        }
    }];
}

- (void)saveVideoSrc:(NSString *)videoSrc forSrcIndex:(NSInteger)srcIndex setNum:(NSInteger)setNum
{
    Video *video = [self videoAtSetNum:@(setNum)];
    [video saveVideoSrc:videoSrc forSrcIndex:srcIndex];
}


- (Video *)firstVideo
{
    return [Video MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"videoGroup == %@", self] sortedBy:@"setNum" ascending:YES inContext:self.managedObjectContext];
}
     

#pragma mark Debug
- (void)debugPrint
{
    NSLog(@"%@", self);
    NSLog(@"Videos: \n");
    for (Video *video in self.videos) {
        NSLog(@"[%@] %@", video.setNum, video);
    }
}

@end
