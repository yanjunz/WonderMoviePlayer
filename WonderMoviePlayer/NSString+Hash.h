//
//  NSString+Hash.h
//  mtt
//
//  Created by allensun on 13-8-27.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Hash)

- (NSString *)MD5;
- (NSString *)SHA1;
- (NSString *)SHA256;
- (NSString *)SHA512;

@end
