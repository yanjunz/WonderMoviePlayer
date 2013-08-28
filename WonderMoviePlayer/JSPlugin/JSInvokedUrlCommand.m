//
//  JSInvokedUrlCommand.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-28.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "JSInvokedUrlCommand.h"

@implementation JSInvokedUrlCommand
@synthesize arguments = _arguments;
@synthesize callbackId = _callbackId;
@synthesize className = _className;
@synthesize methodName = _methodName;

+ (JSInvokedUrlCommand*)commandFromJson:(NSArray*)jsonEntry
{
    return [[JSInvokedUrlCommand alloc] initWithJson:jsonEntry];
}

- (id)initWithJson:(NSArray *)jsonEntry
{
    id tmp = [jsonEntry objectAtIndex:0];
    NSString* callbackId = tmp == [NSNull null] ? nil : tmp;
    NSString* className = [jsonEntry objectAtIndex:1];
    NSString* methodName = [jsonEntry objectAtIndex:2];
    NSMutableArray* arguments = [jsonEntry objectAtIndex:3];
    
    return [self initWithArguments:arguments
                        callbackId:callbackId
                         className:className
                        methodName:methodName];
}

- (id)initWithArguments:(NSArray*)arguments
             callbackId:(NSString*)callbackId
              className:(NSString*)className
             methodName:(NSString*)methodName
{
    self = [super init];
    if (self != nil) {
        _arguments = arguments;
        _callbackId = callbackId;
        _className = className;
        _methodName = methodName;
    }
//    [self massageArguments];
    return self;
}

- (void)dealloc
{
    [_arguments release];
    [_callbackId release];
    [_className release];
    [_methodName release];
    [super dealloc];
}
@end
