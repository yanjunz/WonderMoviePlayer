//
//  JSVideoPlugin.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-28.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "JSVideoPlugin.h"
#import "JSInvokedUrlCommand.h"

@implementation JSVideoPlugin

- (void)play:(JSInvokedUrlCommand *)command
{
    if (command.arguments.count == 0) {
        return;
    }
    
    NSString *src = command.arguments[0];
    NSLog(@"[JSVideoPlugin] play %@", src);
}

@end
