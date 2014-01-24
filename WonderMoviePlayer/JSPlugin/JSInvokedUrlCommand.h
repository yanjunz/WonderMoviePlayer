//
//  JSInvokedUrlCommand.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-28.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSInvokedUrlCommand : NSObject {
    NSString* __weak _callbackId;
    NSString* __weak _className;
    NSString* __weak _methodName;
    NSArray* __weak _arguments;
}

@property (weak, nonatomic, readonly) NSArray* arguments;
@property (weak, nonatomic, readonly) NSString* callbackId;
@property (weak, nonatomic, readonly) NSString* className;
@property (weak, nonatomic, readonly) NSString* methodName;

+ (JSInvokedUrlCommand*)commandFromJson:(NSArray*)jsonEntry;

- (id)initWithArguments:(NSArray*)arguments
             callbackId:(NSString*)callbackId
              className:(NSString*)className
             methodName:(NSString*)methodName;

- (id)initFromJson:(NSArray*)jsonEntry;

@end
