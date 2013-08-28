//
//  JSJSON.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-28.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (CDVJSONSerializing)
- (NSString*)JSONString;
@end

@interface NSDictionary (CDVJSONSerializing)
- (NSString*)JSONString;
@end

@interface NSString (CDVJSONSerializing)
- (id)JSONObject;
@end

