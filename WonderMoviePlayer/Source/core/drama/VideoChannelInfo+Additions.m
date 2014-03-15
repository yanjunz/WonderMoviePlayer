//
//  VideoChannelInfo+Additions.m
//  mtt
//
//  Created by Zhuang Yanjun on 14/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "VideoChannelInfo+Additions.h"

@implementation VideoChannelInfo (Additions)

+ (instancetype)videoChannelInfoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum srcIndex:(NSInteger)srcIndex
{
    return [self videoChannelInfoWithVideoId:videoId setNum:setNum srcIndex:srcIndex inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (instancetype)videoChannelInfoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum srcIndex:(NSInteger)srcIndex inContext:(NSManagedObjectContext *)context
{
    return [self MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"video.videoGroup.videoId == %@ AND video.setNum == %d AND srcIndex == %d", videoId, setNum, srcIndex] inContext:context];
}

+ (instancetype)videoChannelInfoWithURL:(NSString *)URL
{
    return [self videoChannelInfoWithURL:URL inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (instancetype)videoChannelInfoWithURL:(NSString *)URL inContext:(NSManagedObjectContext *)context
{
    return [self MR_findFirstByAttribute:@"url" withValue:URL inContext:context];
}

+ (instancetype)videoChannelInfoWithVideoSrc:(NSString *)videoSrc
{
    return [self videoChannelInfoWithVideoSrc:videoSrc inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (instancetype)videoChannelInfoWithVideoSrc:(NSString *)videoSrc inContext:(NSManagedObjectContext *)context
{
    return [self MR_findFirstByAttribute:@"videoSrc" withValue:videoSrc inContext:context];
}


@end
