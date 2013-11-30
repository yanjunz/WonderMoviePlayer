//
//  VideoGroup+VideoDetailSet.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "VideoGroup+VideoDetailSet.h"
#import "Video.h"

static NSString *const kVideosKey = @"videos";

@implementation VideoGroup (VideoDetailSet)

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

- (NSArray *)sortedVideos
{
    return [self.videos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"setNum" ascending:YES]]];
}

- (BOOL)isValidDrama
{
    return !(self.totalCount.intValue == 0 && self.maxId.intValue == 0 && self.showType.intValue == VideoGroupShowTypeNone);
}

@end
