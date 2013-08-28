//
//  JSURLProtocol.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-28.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "JSURLProtocol.h"
#import "JSPluginEngine.h"
#import "JSInvokedUrlCommand.h"
#import "JSJSON.h"
#include <objc/message.h>

NSString *const kJSPluginCommandPrefix = @"/!qq_exec";

@interface JSHTTPURLResponse : NSHTTPURLResponse
@property (nonatomic) NSInteger statusCode;
@end

@implementation JSURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)theRequest
{
    NSURL *theURL = theRequest.URL;
//    NSLog(@"path = %@, URL = %@", theURL.path, theURL);
    if ([[theURL path] isEqualToString:kJSPluginCommandPrefix]) {
        NSString *cmds = [theRequest valueForHTTPHeaderField:@"cmds"];
        NSString *requestId = [theRequest valueForHTTPHeaderField:@"rc"];
        cmds = cmds.length > 0 ? cmds : @"";
        requestId = requestId.length > 0 ? requestId : @"0";
        [[JSPluginEngine sharedInstance].commandQueue performSelectorOnMainThread:@selector(enqueCommandJSON:) withObject:@{@"cmds" : cmds, @"rc" : requestId} waitUntilDone:NO];
        return YES;
    }
    return NO;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request
{
    return request;
}

- (void)startLoading
{
    NSURL* url = [[self request] URL];
    
    if ([[url path] isEqualToString:kJSPluginCommandPrefix]) {
        [self sendResponseWithResponseCode:200 data:nil mimeType:nil];
        return;
    }
    
    [self sendResponseWithResponseCode:401 data:[@"" dataUsingEncoding:NSASCIIStringEncoding] mimeType:nil];
}

- (void)stopLoading
{
    // do any cleanup here
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest*)requestA toRequest:(NSURLRequest*)requestB
{
    return NO;
}

- (void)sendResponseWithResponseCode:(NSInteger)statusCode data:(NSData*)data mimeType:(NSString*)mimeType
{
    if (mimeType == nil) {
        mimeType = @"text/plain";
    }
    NSString* encodingName = [@"text/plain" isEqualToString : mimeType] ? @"UTF-8" : nil;
    JSHTTPURLResponse* response =
    [[JSHTTPURLResponse alloc] initWithURL:[[self request] URL]
                                  MIMEType:mimeType
                     expectedContentLength:[data length]
                          textEncodingName:encodingName];
    response.statusCode = statusCode;
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    if (data != nil) {
        [[self client] URLProtocol:self didLoadData:data];
    }
    [[self client] URLProtocolDidFinishLoading:self];
}

@end

@implementation JSHTTPURLResponse
@synthesize statusCode;
@end
