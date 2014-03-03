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

@end
