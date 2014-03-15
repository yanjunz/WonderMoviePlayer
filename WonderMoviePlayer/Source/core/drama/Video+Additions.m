//
//  Video+Additions.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "Video+Additions.h"
#import "VideoGroup+Additions.h"
#import "VideoChannelInfo.h"
#import "VideoHistoryEntry.h"

@implementation Video (Additions)

+ (instancetype)videoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum
{
    return [self videoWithVideoId:videoId setNum:setNum inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (instancetype)videoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum inContext:(NSManagedObjectContext *)context
{
    return [Video MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"videoGroup.videoId == %@ AND setNum == %d", videoId, setNum] inContext:context];
}

+ (instancetype)videoWithWebURL:(NSString *)URL
{
    VideoChannelInfo *videoChannelInfo = [VideoChannelInfo MR_findFirstByAttribute:@"url" withValue:URL];
    return videoChannelInfo.video;
}

- (VideoChannelInfo *)videoChannelInfoAtSrcIndex:(NSInteger)srcIndex
{
    for (VideoChannelInfo *videoChannelInfo in self.videoChannelInfos) {
        if (videoChannelInfo.srcIndex.intValue == srcIndex) {
            return videoChannelInfo;
        }
    }
    return nil;
}

- (VideoChannelInfo *)videoChannelInfoAtWebURL:(NSString *)webURL
{
    for (VideoChannelInfo *videoChannelInfo in self.videoChannelInfos) {
        if ([videoChannelInfo.url isEqualToString:webURL]) {
            return videoChannelInfo;
        }
    }
    return nil;
}

- (VideoChannelInfo *)bestVideoChannelInfo
{
    VideoChannelInfo *videoChannelInfo = nil;
    if (self.videoHistoryEntry) {
        videoChannelInfo = [self videoChannelInfoAtSrcIndex:self.videoHistoryEntry.srcIndex.integerValue];
    }
    if (videoChannelInfo == nil) {
        videoChannelInfo = [self.videoChannelInfos anyObject];
    }
    return videoChannelInfo;
}

- (NSString *)displayName
{
    return [self.videoGroup displayNameForSetNum:self.setNum];
}

- (BOOL)hasLocalFile
{
    return self.path.length > 0;
}

- (void)saveVideoSrc:(NSString *)videoSrc forSrcIndex:(NSInteger)srcIndex
{
    VideoChannelInfo *videoChannelInfo = [self videoChannelInfoAtSrcIndex:srcIndex];
    videoChannelInfo.videoSrc = videoSrc;
}

- (NSString *)webURLAtSrcIndex:(NSInteger)srcIndex
{
    return [self videoChannelInfoAtSrcIndex:srcIndex].url;
}

@end
