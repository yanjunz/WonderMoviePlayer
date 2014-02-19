//
//  NSString+Hash.m
//  mtt
//
//  Created by allensun on 13-8-27.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "NSString+Hash.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Hash)

- (NSString *)MD5
{
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5(data.bytes, data.length, digest);
	
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i){
		[output appendFormat:@"%02x", digest[i]];
	}
	return output;
}

- (NSString *)SHA1
{
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t digest[CC_SHA1_DIGEST_LENGTH];
	
	CC_SHA1(data.bytes, data.length, digest);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH*2];
	for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i){
		[output appendFormat:@"%02x", digest[i]];
	}
	return output;
}

- (NSString *)SHA256
{
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t digest[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(data.bytes, data.length, digest);
	
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
	for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i){
		[output appendFormat:@"%02x", digest[i]];
	}
	return output;
}

- (NSString *)SHA512
{
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
	uint8_t digest[CC_SHA512_DIGEST_LENGTH];
	CC_SHA512(data.bytes, data.length, digest);
	
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH*2];
	for (int i = 0; i < CC_SHA512_DIGEST_LENGTH; ++i){
		[output appendFormat:@"%02x", digest[i]];
	}
	return output;
}


@end
