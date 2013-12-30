//
//  WonderMovieURLProtocol.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 12/25/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "WonderMovieURLProtocol.h"

static NSString *PBProxyURLHeader = @"X-PB";

@interface WonderMovieURLProtocol ()
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSURLRequest *request;
@end

@implementation WonderMovieURLProtocol

- (void)appendData:(NSData *)newData {
    if( _data == nil ) {
        _data = [[NSMutableData alloc] initWithData:newData];
    }
    else
    {
        [_data appendData:newData];
    }
}


- (void)dealloc
{
    self.connection = nil;
    self.data = nil;
    self.request = nil;
    [super dealloc];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([request valueForHTTPHeaderField:PBProxyURLHeader] == nil &&
        [[[request URL] scheme] isEqualToString:@"http"] &&
        [[[request HTTPMethod] lowercaseString] isEqualToString:@"get"]) {
        NSLog(@"canInitWithRequest %@", request);
        return YES;
    }
    else {
        return NO;
    }
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (id)initWithRequest:(NSURLRequest *)request
      cachedResponse:(NSCachedURLResponse *)cachedResponse
              client:(id <NSURLProtocolClient>)client
{
    NSLog(@"initWithRequest %@, %@", request, cachedResponse);
    // Modify request
    NSMutableURLRequest *myRequest = [request mutableCopy];
    [myRequest setValue:@"" forHTTPHeaderField:PBProxyURLHeader];
    
    self = [super initWithRequest:myRequest
                   cachedResponse:cachedResponse
                           client:client];
    
    if ( self ) {
        [self setRequest:myRequest];
    }
    return self;
}

- (void)startLoading
{
    //  use the regular URL donwload machinery to get the url contents
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:[self request]
                                                                delegate:self];
    [self setConnection:connection];
}

-(void)stopLoading {
    [[self connection] cancel];
}

// NSURLConnection delegates (generally we pass these on to our client)

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self client] URLProtocol:self didLoadData:data];
    [self appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [[self client] URLProtocol:self didFailWithError:error];
	[self setConnection:nil];
	[_data release]; _data = nil;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *rsp = (NSHTTPURLResponse *)response;
    NSLog(@"didReceiveResponse %@, %@", connection.currentRequest, [rsp allHeaderFields]);
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[self client] URLProtocolDidFinishLoading:self];
	[self setConnection:nil];
	[_data release]; _data = nil;
}

@end
