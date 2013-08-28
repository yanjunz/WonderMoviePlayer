//
//  JSCommandQueue.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-28.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSInvokedUrlCommand.h"

@interface JSCommandQueue : NSObject {
    BOOL _currentlyExecuting;
}

@property (nonatomic, readonly) BOOL currentlyExecuting;
- (void)enqueCommandJSON:(NSString*)cmdJSON;
@end
