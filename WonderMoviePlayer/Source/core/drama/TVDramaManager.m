//
//  TVDramaManager.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "TVDramaManager.h"
#import "VideoGroup.h"
#import "VideoGroup+VideoDetailSet.h"
#import "Video.h"

@interface TVDramaManager ()
@property (nonatomic, retain) NSMutableArray *handlers;
@end

@implementation TVDramaManager

- (id)init
{
    if (self = [super init]) {
        self.handlers = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    self.webURL = nil;
    self.videoGroup = nil;
    self.handlers = nil;
    [super dealloc];
}

- (void)addRequestHandler:(id<TVDramaRequestHandler>)handler
{
    if (![self.handlers containsObject:handler]) {
        [self.handlers addObject:handler];
    }
}

- (void)removeRequestHandler:(id<TVDramaRequestHandler>)handler
{
    [self.handlers removeObject:handler];
}

- (VideoGroup *)videoGroupInCurrentThread
{
    return [self.videoGroup MR_inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

- (BOOL)getDramaInfo:(TVDramaRequestType)requestType
{
    if (self.webURL.length > 0) {
        for (id<TVDramaRequestHandler> handler in self.handlers) {
            if ([handler respondsToSelector:@selector(tvDramaManager:requestDramaInfoWithURL:curSetNum:requestType:)]) {
                int curSetNum = 0;
                VideoGroup *videoGroup = [handler tvDramaManager:self requestDramaInfoWithURL:self.webURL curSetNum:&curSetNum requestType:requestType];
                self.curSetNum = curSetNum;
                self.videoGroup = videoGroup;
                return YES;
            }
        }
    }
    return NO;
}

- (void)getDramaInfo:(TVDramaRequestType)requestType completionBlock:(void (^)(BOOL success))completionBlock
{
    if (self.webURL.length == 0) {
        if (completionBlock)
            completionBlock(NO);
        return;
    }
    
    __block BOOL hasSuccessed = NO;
    __block int remainingCallbackCount = self.handlers.count;
    for (id<TVDramaRequestHandler> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(tvDramaManager:requestDramaInfoWithURL:requestType:completionBlock:)]) {
            [handler tvDramaManager:self requestDramaInfoWithURL:self.webURL requestType:requestType completionBlock:^(VideoGroup *videoGroup, int curSetNum) {
                NSLog(@"remainingCallbackCount = %d, curSetNum=%d", remainingCallbackCount, curSetNum);
                BOOL success = videoGroup != nil;
                
                if (success && !hasSuccessed) { // no success before yet, but success this time, should be callback with success
                    self.curSetNum = curSetNum;
                    self.videoGroup = videoGroup;
                    
                    hasSuccessed = YES;
                    if (completionBlock) {
                        completionBlock(YES);
                    }
                }
                else if (remainingCallbackCount == 1 && !hasSuccessed) { // the last handler callback and on success before yet
                    if (completionBlock) {
                        completionBlock(NO);
                    }
                }
                remainingCallbackCount --;
            }];
        }
        else {
            remainingCallbackCount --;
        }
    }
}

- (BOOL)sniffVideoSource
{
    if (self.webURL.length > 0) {
        VideoGroup *videoGroup = [self videoGroupInCurrentThread];
        for (id<TVDramaRequestHandler> handler in self.handlers) {
            if ([handler respondsToSelector:@selector(tvDramaManager:sniffVideoSrcWithURL:src:)]) {
                NSString *videoSrc = [handler tvDramaManager:self sniffVideoSrcWithURL:self.webURL src:videoGroup.src];
                if (videoSrc.length > 0) {
                    Video *video = [videoGroup videoAtURL:self.webURL];
                    video.videoSrc = videoSrc;
                    [[NSManagedObjectContext MR_contextForCurrentThread] save:NULL];
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)sniffVideoSource:(void (^)(BOOL success))completionBlock
{
    if (self.webURL.length == 0) {
        if (completionBlock)
            completionBlock(NO);
        return;
    }
    
    __block BOOL hasSuccessed = NO;
    __block int remainingCallbackCount = self.handlers.count;
    VideoGroup *videoGroup = [self videoGroupInCurrentThread];
    for (id<TVDramaRequestHandler> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(tvDramaManager:sniffVideoSrcWithURL:src:completionBlock:)]) {
            [handler tvDramaManager:self sniffVideoSrcWithURL:self.webURL src:videoGroup.src completionBlock:^(NSString *videoSrc) {
                BOOL success = videoSrc.length > 0;
                NSLog(@"sniffVideoSource %@", videoSrc);
                
                if (success && !hasSuccessed) { // no success before yet, but success this time, should be callback with success
                    Video *video = [videoGroup videoAtURL:self.webURL];
                    video.videoSrc = videoSrc;
                    [[NSManagedObjectContext MR_contextForCurrentThread] save:NULL];
                    
                    hasSuccessed = YES;
                    if (completionBlock) {
                        completionBlock(YES);
                    }
                }
                else if (remainingCallbackCount == 1 && !hasSuccessed) { // the last handler callback and on success before yet
                    if (completionBlock) {
                        completionBlock(NO);
                    }
                }
                remainingCallbackCount --;
            }];
        }
        else {
            remainingCallbackCount --;
        }
    }
}

- (BOOL)hasNext
{
    VideoGroup *videoGroup = [self videoGroupInCurrentThread];
    return videoGroup && _curSetNum > 0 && _curSetNum < videoGroup.maxId.intValue;
}

@end
