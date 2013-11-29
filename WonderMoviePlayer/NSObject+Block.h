//
//  NSObject+Block.h
//  mtt
//
//  Created by Zhuang Yanjun on 13-7-25.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Block)
- (void)performBlockInMainThread:(void(^)(void))block afterDelay:(NSTimeInterval)delay;
- (void)performBlockInBackground:(void(^)(void))block;
@end
