//
//  TVDramaManager.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "TVDramaManager.h"
#import "VideoGroup.h"
#import "VideoGroup+Additions.h"
#import "Video.h"
#import "NSString+Hash.h"

@interface TVDramaManager ()
@property (nonatomic, strong) NSMutableArray *handlers;
@end

@implementation TVDramaManager

- (id)init
{
    if (self = [super init]) {
        self.handlers = [NSMutableArray array];
    }
    return self;
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

- (Video *)playingVideo
{
    VideoGroup *videoGroup = [self videoGroupInCurrentThread];
    return [videoGroup isValidDrama] ? [videoGroup videoAtSetNum:@(self.curSetNum)] : [videoGroup.videos anyObject];
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
    DefineWeakSelfBeforeBlock();
    for (id<TVDramaRequestHandler> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(tvDramaManager:requestDramaInfoWithURL:requestType:completionBlock:)]) {
            [handler tvDramaManager:self requestDramaInfoWithURL:self.webURL requestType:requestType completionBlock:^(VideoGroup *videoGroup, int curSetNum) {
                DefineStrongSelfInBlock(sself);
//                NSLog(@"remainingCallbackCount = %d, curSetNum=%d", remainingCallbackCount, curSetNum);
                BOOL success = videoGroup != nil;
                
                if (remainingCallbackCount <= 0) {
                    return;
                }
                
                if (success && !hasSuccessed) { // no success before yet, but success this time, should be callback with success
                    sself.curSetNum = curSetNum;
                    sself.videoGroup = videoGroup;
                    
                    hasSuccessed = YES;
                    [sself fullFillVideoGroup:YES];
                    if (completionBlock) {
                        completionBlock(YES);
                    }
                }
                else if (remainingCallbackCount == 1 && !hasSuccessed) { // the last handler callback and on success before yet
                    [sself fullFillVideoGroup:NO];
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
//                NSLog(@"sniffVideoSource %@, %d", videoSrc, remainingCallbackCount);
                
                if (remainingCallbackCount <= 0) {
                    return;
                }
                
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

#pragma mark Private
- (void)fullFillVideoGroup:(BOOL)hasVideoGroup
{
    __block VideoGroup *videoGroup = hasVideoGroup ? [self videoGroupInCurrentThread] : nil;
    DefineWeakSelfBeforeBlock();
    
    // Add one video object for non-drama video group
    if (![videoGroup isValidDrama]) {
        [MagicalRecord saveUsingCurrentThreadContextWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            DefineStrongSelfInBlock(sself);
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateFormat = @"yyyyMMddhhmmss";
            NSString *title = [NSString stringWithFormat:@"视频 %@",  [df stringFromDate:[NSDate date]]];

            if (videoGroup == nil) {
                NSString *videoId = [sself generateVideoIdWithKey:sself.webURL];
                videoGroup = [VideoGroup MR_findFirstByAttribute:@"videoId" withValue:videoId inContext:localContext];
                if (videoGroup == nil) {
                    // Need create a videoGroup for it
                    videoGroup = [VideoGroup MR_createInContext:localContext];
                    videoGroup.videoName = title;
                    videoGroup.videoId = videoId;
                }
            }
            
            int count = videoGroup.videos.count;
            Video *updatedVideo = nil;
            if (count == 1) { // already has one video, just update it
                updatedVideo = [videoGroup.videos anyObject];
            }
            else {
                if (count > 1) { // has more than one video, data should be corrupted, just clear it
                    [videoGroup removeVideos:videoGroup.videos];
                }
                updatedVideo = [Video MR_createInContext:localContext]; // create one
            }
            updatedVideo.brief = title;
            updatedVideo.url = sself.webURL;
            sself.curSetNum = 0;
            sself.videoGroup = videoGroup;            
            [videoGroup setVideo:updatedVideo atSetNum:0 inContext:localContext];
        }];
    }
}

- (NSString *)generateVideoIdWithKey:(NSString *)key
{
    NSString *md5 = [key MD5];
    return md5;
}

@end
