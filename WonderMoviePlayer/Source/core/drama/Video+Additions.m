//
//  Video+Additions.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "Video+Additions.h"
#import "VideoGroup+Additions.h"

@implementation Video (Additions)

+ (Video *)videoWithVideoId:(NSString *)videoId srcIndex:(NSInteger)srcIndex setNum:(NSInteger)setNum
{
    return [self videoWithVideoId:videoId srcIndex:srcIndex setNum:setNum inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (Video *)videoWithVideoId:(NSString *)videoId srcIndex:(NSInteger)srcIndex setNum:(NSInteger)setNum inContext:(NSManagedObjectContext *)context
{
    return [Video MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"videoId == %@ AND srcIndex == %d AND setNum == %d", videoId, srcIndex, setNum] inContext:context];
}

- (NSString *)displayName
{
    return [self.videoGroup displayNameForSetNum:self.setNum];
}

@end
