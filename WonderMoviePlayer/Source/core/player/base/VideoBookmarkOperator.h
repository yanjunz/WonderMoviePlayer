//
//  VideoBookmarkOperator.h
//  mtt
//
//  Created by Zhuang Yanjun on 17/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VideoBookmarkOperator <NSObject>
- (void)bookmarkVideoGroup:(VideoGroup *)videoGroup bookmark:(BOOL)bookmark;
- (void)removeAllVideoBookmarks;
- (BOOL)isVideoGroupBookmarked:(VideoGroup *)videoGroup;
@end
