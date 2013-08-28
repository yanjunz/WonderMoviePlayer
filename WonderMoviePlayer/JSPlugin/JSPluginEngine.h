//
//  JSPluginEngine.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-28.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSPlugin.h"
#import "JSCommandQueue.h"

@interface JSPluginEngine : NSObject
//@property (nonatomic, assign) UIWebView *webView;
@property (nonatomic, retain) NSMutableDictionary *pluginsMap;
@property (nonatomic, retain) JSCommandQueue *commandQueue;

+ (JSPluginEngine *)sharedInstance;
- (void)registerPlugin:(JSPlugin *)plugin withPluginName:(NSString*)pluginName;
- (JSPlugin *)getCommandInstance:(NSString *)pluginName;
@end
