//
//  VideoGroup+Bookmark.m
//  mtt
//
//  Created by Zhuang Yanjun on 1/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "VideoGroup+Bookmark.h"
#import "VideoHistoryEntry.h"
#import "VideoBookmarkEntry.h"
#import "VideoGroup+History.h"

@implementation VideoGroup (Bookmark)

- (void)checkUpdateForBookmarkInContext:(NSManagedObjectContext *)context
{
    VideoBookmarkEntry *bookmarkEntry = self.videoBookmarkEntry;
    if (bookmarkEntry) {
        VideoHistoryEntry *historyEntry = [self getLastestVideoHistoryEntryInContext:context];
        
        if (historyEntry == nil || // has no play history yet
            historyEntry.time.longValue < self.setUpdateTime.longValue) { // or the last play time < set update time
            bookmarkEntry.hasUpdate = @(YES);
        }
    }
}

- (BOOL)isBookmarked
{
    return self.videoBookmarkEntry != nil;
}

@end
