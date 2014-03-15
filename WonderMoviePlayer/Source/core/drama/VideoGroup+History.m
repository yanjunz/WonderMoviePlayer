//
//  VideoGroup+History.m
//  mtt
//
//  Created by Zhuang Yanjun on 14/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "VideoGroup+History.h"
#import "VideoHistoryEntry.h"

@implementation VideoGroup (History)

- (VideoHistoryEntry *)getLastestVideoHistoryEntry
{
    return [self getLastestVideoHistoryEntryInContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

- (VideoHistoryEntry *)getLastestVideoHistoryEntryInContext:(NSManagedObjectContext *)context
{
    return [VideoHistoryEntry MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"video.videoGroup == %@", self] sortedBy:@"time" ascending:NO inContext:context];
}

@end
