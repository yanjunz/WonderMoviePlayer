//
//  NSObject+Block.m
//  mtt
//
//  Created by Zhuang Yanjun on 13-7-25.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "NSObject+Block.h"

@implementation NSObject (Block)

- (void)performBlockInMainThread:(void(^)(void))block afterDelay:(NSTimeInterval)delay
{
    int64_t delta = (int64_t)(1.0e9 * delay);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta), dispatch_get_main_queue(), block);
}

- (void)performBlockInBackground:(void(^)(void))block
{
    dispatch_async(dispatch_get_global_queue(0, 0), block);
}


@end
