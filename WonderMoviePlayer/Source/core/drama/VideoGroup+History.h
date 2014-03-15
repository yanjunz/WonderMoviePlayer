//
//  VideoGroup+History.h
//  mtt
//
//  Created by Zhuang Yanjun on 14/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "VideoGroup.h"

@class VideoHistoryEntry;

@interface VideoGroup (History)

- (VideoHistoryEntry *)getLastestVideoHistoryEntry;

- (VideoHistoryEntry *)getLastestVideoHistoryEntryInContext:(NSManagedObjectContext *)context;

@end
