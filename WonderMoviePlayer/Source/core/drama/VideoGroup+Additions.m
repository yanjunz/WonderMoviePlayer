//
//  VideoGroup+Additions.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "VideoGroup+Additions.h"
#import "Video.h"

@implementation VideoGroup (Additions)

+ (VideoGroup *)videoGroupWithVideoId:(NSString *)videoId srcIndex:(NSInteger)srcIndex
{
    return [self videoGroupWithVideoId:videoId srcIndex:srcIndex inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (VideoGroup *)videoGroupWithVideoId:(NSString *)videoId srcIndex:(NSInteger)srcIndex inContext:(NSManagedObjectContext *)context
{
    return [VideoGroup MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"videoId == %@ AND srcIndex == %d", videoId, srcIndex] inContext:context];
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
    if (desc == nil) {
        return [NSString stringWithFormat:@"%d", srcIndex];
    }
    else {
        return desc;
    }
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
    __block Video *video = nil;
    [self.videos enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Video *t = obj;
        if ([t.url isEqualToString:URL]) {
            video = t;
            *stop = YES;
        }
    }];
    return video;
}

- (Video *)videoAtSetNum:(NSNumber *)setNum
{
    __block Video *video = nil;
    [self.videos enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Video *t = obj;
        if (t.setNum.intValue == setNum.intValue) {
            video = t;
            *stop = YES;
        }
    }];
    return video;
}

- (void)setVideo:(Video *)video atSetNum:(NSNumber *)setNum inContext:(NSManagedObjectContext *)context
{
    Video *existedVideo = [self videoAtSetNum:setNum];
    if (existedVideo) {
        if (existedVideo != video) {
            NSLog(@"Warning: video detail data corrupted");
            [self removeVideosObject:existedVideo];
            [existedVideo MR_deleteInContext:context];
        }
    }
    else {
        [self addVideosObject:video];
    }
}

- (NSArray *)sortedVideos:(BOOL)ascending
{
    return [self.videos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"setNum" ascending:ascending]]];
}

- (BOOL)isValidDrama
{
    return !(self.totalCount.intValue == 0 && self.maxId.intValue == 0 && self.showType.intValue == VideoGroupShowTypeNone);
}

- (BOOL)isRecognized
{
    return [self.srcIndex intValue] != 0 || self.src.length > 0 || [self isValidDrama];
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
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"yyyyMMddhhmmss";
        return [NSString stringWithFormat:@"视频 %@",  [df stringFromDate:[NSDate date]]];
    }
}

- (NSArray *)downloadedVideos
{
    NSArray *videos = [[self.videos filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"path.length > 0"]]
                       sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"setNum" ascending:YES]]];
    return videos;
}

- (void)checkDownloadedVideosExist
{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        VideoGroup *videoGroupInContext = [self MR_inContext:localContext];
        NSSet *downloadVideos = [videoGroupInContext.videos filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"path.length > 0"]];
        for (Video *video in downloadVideos) {
            NSString *downloadingPath = [NSString stringWithFormat:@"%@/.%@", [video.path stringByDeletingLastPathComponent], [video.path lastPathComponent]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:video.path] &&
                ![[NSFileManager defaultManager] fileExistsAtPath:downloadingPath]) {
                video.path = nil;
            }
        }
    }];
}

@end
