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
@end

@implementation TVDramaManager

- (id)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)dealloc
{
    self.videoGroup = nil;
    self.requestHandler = nil;
//    NSLog(@"TVDramaManager dealloc");
}

- (VideoGroup *)videoGroupInCurrentThread
{
    return [self.videoGroup MR_inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

- (Video *)playingVideo
{
    VideoGroup *videoGroup = [self videoGroupInCurrentThread];
    Video* ret = [videoGroup isValidDrama] ? [videoGroup videoAtSetNum:@(self.curSetNum)] : [videoGroup.videos anyObject];
    
    ret.videoSrc = self.playingURL;
    
    return ret;
}

- (void)getDramaInfo:(TVDramaRequestType)requestType completionBlock:(void (^)(BOOL success))completionBlock
{
    if (self.webURL.length == 0) {
        if (completionBlock)
            completionBlock(NO);
        return;
    }
    
    DefineWeakSelfBeforeBlock();
    [self.requestHandler tvDramaManager:self requestDramaInfoWithURL:self.webURL requestType:requestType completionBlock:^(VideoGroup *videoGroup, int curSetNum) {
        DefineStrongSelfInBlock(sself);
        if (videoGroup) {
            sself.curSetNum = curSetNum;
            sself.videoGroup = videoGroup;
            
            [sself fullFillVideoGroup:YES];
            if (completionBlock) {
                completionBlock(YES);
            }
        }
        else {
            [sself fullFillVideoGroup:NO];
            if (completionBlock) {
                completionBlock(NO);
            }
        }
    }];
}

- (void)sniffVideoSource:(void (^)(BOOL success))completionBlock
{
    if (self.webURL.length == 0) {
        if (completionBlock)
            completionBlock(NO);
        return;
    }
    
    DefineWeakSelfBeforeBlock();
    VideoGroup *videoGroup = [self videoGroupInCurrentThread];
    [self.requestHandler tvDramaManager:self sniffVideoSrcWithURL:self.webURL clarity:self.currentClarity src:videoGroup.src completionBlock:^(NSString *videoSrc, NSInteger clarityCount) {
        DefineStrongSelfInBlock(sself);
        if (videoSrc.length > 0) {
            Video *video = [videoGroup videoAtURL:self.webURL];
            video.videoSrc = videoSrc;
            [[NSManagedObjectContext MR_contextForCurrentThread] save:NULL];
            
//            sself.clarityCount = clarityCount;// No need to set here, it will get clarity count ASAP
            
            if (completionBlock) {
                completionBlock(YES);
            }
        }
        else {
            if (completionBlock) {
                completionBlock(NO);
            }
        }
    }];
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
            
            NSString *title = [videoGroup displayNameForSetNum:nil];
            
            if (videoGroup == nil) {
                NSString *videoId = [sself generateVideoIdWithKey:sself.webURL];
                videoGroup = [VideoGroup MR_findFirstByAttribute:@"videoId" withValue:videoId inContext:localContext];
                if (videoGroup == nil) {
                    // Need create a videoGroup for it
                    videoGroup = [VideoGroup MR_createInContext:localContext];
                    videoGroup.videoName = [videoGroup displayNameForSetNum:nil];
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

@implementation CompositeTVDramaRequestHandler

- (id)init
{
    if (self = [super init]) {
        self.handlers = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)handlerWithHandlers:(NSArray *)handlers
{
    CompositeTVDramaRequestHandler *instance = [[CompositeTVDramaRequestHandler alloc] init];
    [instance.handlers addObjectsFromArray:handlers];
    return instance;
}

- (void)addHandler:(id<TVDramaRequestHandler>)handler
{
    [self.handlers addObject:handler];
}
- (void)removeHandler:(id<TVDramaRequestHandler>)hanlder
{
    [self.handlers removeObject:hanlder];
}

- (void)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL requestType:(TVDramaRequestType)requestType completionBlock:(void (^)(VideoGroup *videoGroup, int curSetNum))completionBlock
{
    __block BOOL hasSuccessed = NO;
    __block int remainingCallbackCount = self.handlers.count;
    for (id<TVDramaRequestHandler> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(tvDramaManager:requestDramaInfoWithURL:requestType:completionBlock:)]) {
            [handler tvDramaManager:manager requestDramaInfoWithURL:URL requestType:requestType completionBlock:^(VideoGroup *videoGroup, int curSetNum) {
//                NSLog(@"[P2] requestDramaInfoWithURL  %d, %d, handler = %@", remainingCallbackCount, curSetNum, handler);
                BOOL success = videoGroup != nil;
                
                if (remainingCallbackCount <= 0) {
                    return;
                }
                
                if (success && !hasSuccessed) { // no success before yet, but success this time, should be callback with success
                    hasSuccessed = YES;
                    if (completionBlock) {
                        completionBlock(videoGroup, curSetNum);
                    }
                }
                else if (remainingCallbackCount == 1 && !hasSuccessed) { // the last handler callback and on success before yet
                    if (completionBlock) {
                        completionBlock(nil, 0);
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

- (void)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURL:(NSString *)URL clarity:(NSInteger)clarity src:(NSString *)src completionBlock:(void (^)(NSString *videoSrc, NSInteger clarityCount))completionBlock
{
    __block BOOL hasSuccessed = NO;
    __block int remainingCallbackCount = self.handlers.count;

    for (id<TVDramaRequestHandler> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(tvDramaManager:sniffVideoSrcWithURL:clarity:src:completionBlock:)]) {
            [handler tvDramaManager:manager sniffVideoSrcWithURL:URL clarity:clarity src:src completionBlock:^(NSString *videoSrc, NSInteger clarityCount) {
                BOOL success = videoSrc.length > 0;
//                NSLog(@"[P2] sniffVideoSource %@, %d, handler = %@", videoSrc, remainingCallbackCount, handler);
                
                if (remainingCallbackCount <= 0) {
                    return;
                }
                
                if (success && !hasSuccessed) { // no success before yet, but success this time, should be callback with success
                    hasSuccessed = YES;
                    if (completionBlock) {
                        completionBlock(videoSrc, clarityCount);
                    }
                }
                else if (remainingCallbackCount == 1 && !hasSuccessed) { // the last handler callback and on success before yet
                    if (completionBlock) {
                        completionBlock(nil, 0);
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

@end

@implementation ResponsibilityChainTVDramaRequestHandler

+ (instancetype)handlerWithActualHandler:(id<TVDramaRequestHandler>)actualHandler
                             nextHandler:(ResponsibilityChainTVDramaRequestHandler *)nextHandler
{
    ResponsibilityChainTVDramaRequestHandler *instance = [[ResponsibilityChainTVDramaRequestHandler alloc] init];
    instance.actualHandler = actualHandler;
    instance.nextHandler = nextHandler;
    return instance;
}

- (void)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL requestType:(TVDramaRequestType)requestType completionBlock:(void (^)(VideoGroup *videoGroup, int curSetNum))completionBlock
{
    DefineWeakSelfBeforeBlock();
    if ([self.actualHandler respondsToSelector:@selector(tvDramaManager:requestDramaInfoWithURL:requestType:completionBlock:)]) {
        [self.actualHandler tvDramaManager:manager requestDramaInfoWithURL:URL requestType:requestType completionBlock:^(VideoGroup *videoGroup, int curSetNum) {
//            NSLog(@"[P1] requestDramaInfoWithURL  %d, handler = %@", curSetNum, self.actualHandler);
            DefineStrongSelfInBlock(sself);
            if (videoGroup) {
                if (completionBlock) {
                    completionBlock(videoGroup, curSetNum);
                }
            }
            else if (sself.nextHandler) {
                [sself.nextHandler tvDramaManager:manager requestDramaInfoWithURL:URL requestType:requestType completionBlock:completionBlock];
            }
            else {
                if (completionBlock) {
                    completionBlock(nil, 0);
                }
            }
        }];
    }
    else if (self.nextHandler) {
        [self.nextHandler tvDramaManager:manager requestDramaInfoWithURL:URL requestType:requestType completionBlock:completionBlock];
    }
    else {
        if (completionBlock) {
            completionBlock(nil, 0);
        }
    }
}

- (void)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURL:(NSString *)URL clarity:(NSInteger)clarity src:(NSString *)src completionBlock:(void (^)(NSString *videoSrc, NSInteger clarityCount))completionBlock
{
    DefineWeakSelfBeforeBlock();
    if ([self.actualHandler respondsToSelector:@selector(tvDramaManager:sniffVideoSrcWithURL:clarity:src:completionBlock:)]) {
        [self.actualHandler tvDramaManager:manager sniffVideoSrcWithURL:URL clarity:clarity src:src completionBlock:^(NSString *videoSrc, NSInteger clarityCount) {
//            NSLog(@"[P1] sniffVideoSource %@, handler = %@", videoSrc, self.actualHandler);
            DefineStrongSelfInBlock(sself);
            if (videoSrc.length > 0) {
                if (completionBlock) {
                    completionBlock(videoSrc, clarityCount);
                }
            }
            else if (sself.nextHandler) {
                [sself.nextHandler tvDramaManager:manager sniffVideoSrcWithURL:URL clarity:clarity src:src completionBlock:completionBlock];
            }
            else {
                if (completionBlock) {
                    completionBlock(nil, 0);
                }
            }
        }];
    }
    else if (self.nextHandler) {
        [self.nextHandler tvDramaManager:manager sniffVideoSrcWithURL:URL clarity:clarity src:src completionBlock:completionBlock];
    }
    else {
        if (completionBlock) {
            completionBlock(nil, 0);
        }
    }
}

@end
