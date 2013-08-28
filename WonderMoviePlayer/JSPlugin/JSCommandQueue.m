//
//  JSCommandQueue.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-28.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "JSCommandQueue.h"
#import "JSJSON.h"
#import "JSPluginEngine.h"
#import "JSPlugin.h"

@interface JSCommandQueue () {
    NSInteger _lastCommandQueueFlushRequestId;
    NSMutableArray* _queue;
}

@end

@implementation JSCommandQueue

- (id)init
{
    if (self = [super init]) {
        _queue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_queue release];
    [super dealloc];
}

- (void)resetRequestId
{
    _lastCommandQueueFlushRequestId = 0;
}

- (void)enqueCommandJSON:(NSDictionary *)params
{
    NSString *cmds = params[@"cmds"];
    NSString *requestId = params[@"rc"];
    if (requestId.intValue != _lastCommandQueueFlushRequestId && cmds.length > 0) {
        _lastCommandQueueFlushRequestId = requestId.intValue;
        [_queue addObject:cmds];
        [self executePending];
    }
}

- (void)executePending
{
    // Make us re-entrant-safe.
    if (_currentlyExecuting) {
        return;
    }
    @try {
        _currentlyExecuting = YES;
        
        for (NSUInteger i = 0; i < [_queue count]; ++i) {
            // Parse the returned JSON array.
            NSArray* jsonEntry = [[_queue objectAtIndex:i] JSONObject];

            JSInvokedUrlCommand* command = [JSInvokedUrlCommand commandFromJson:jsonEntry];
                
            if (![self execute:command]) {
#ifdef DEBUG
                NSString* commandJson = [jsonEntry JSONString];
                static NSUInteger maxLogLength = 1024;
                NSString* commandString = ([commandJson length] > maxLogLength) ?
                [NSString stringWithFormat:@"%@[...]", [commandJson substringToIndex:maxLogLength]] :
                commandJson;
                
                NSLog(@"FAILED pluginJSON = %@", commandString);
#endif
                
            }
        }
        
        [_queue removeAllObjects];
    } @finally
    {
        _currentlyExecuting = NO;
    }
}

- (BOOL)execute:(JSInvokedUrlCommand*)command
{
    JSPlugin *plugin = [[JSPluginEngine sharedInstance] getCommandInstance:command.className];
    NSString *cmdName = [NSString stringWithFormat:@"%@:", command.methodName];
    SEL normalSelector = NSSelectorFromString(cmdName);
    if ([plugin respondsToSelector:normalSelector]) {
        [plugin performSelector:normalSelector withObject:command];
        return YES;
    }
    else {
        return NO;
    }
}

@end
