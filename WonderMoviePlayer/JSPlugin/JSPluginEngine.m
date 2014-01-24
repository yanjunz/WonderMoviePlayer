//
//  JSPluginEngine.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-28.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "JSPluginEngine.h"

@implementation JSPluginEngine

+ (JSPluginEngine *)sharedInstance
{
    static JSPluginEngine *_instance;
    if (_instance == nil) {
        _instance = [[JSPluginEngine alloc] init];
    }
    return _instance;
}


- (NSMutableDictionary *)pluginsMap
{
    if (_pluginsMap == nil) {
        _pluginsMap = [[NSMutableDictionary alloc] init];
    }
    return _pluginsMap;
}

- (JSCommandQueue *)commandQueue
{
    if (_commandQueue == nil) {
        _commandQueue = [[JSCommandQueue alloc] init];
    }
    return _commandQueue;
}

- (void)registerPlugin:(JSPlugin *)plugin withPluginName:(NSString*)pluginName
{
    [self.pluginsMap setObject:plugin forKey:[pluginName lowercaseString]];
}

- (JSPlugin *)getCommandInstance:(NSString *)pluginName
{
    return [self.pluginsMap objectForKey:[pluginName lowercaseString]];
}

@end
