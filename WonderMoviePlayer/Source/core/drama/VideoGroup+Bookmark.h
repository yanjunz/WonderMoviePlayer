//
//  VideoGroup+Bookmark.h
//  mtt
//
//  Created by Zhuang Yanjun on 1/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "VideoGroup.h"

@interface VideoGroup (Bookmark)
- (void)checkUpdateForBookmarkInContext:(NSManagedObjectContext *)context;
- (BOOL)isBookmarked;
@end
