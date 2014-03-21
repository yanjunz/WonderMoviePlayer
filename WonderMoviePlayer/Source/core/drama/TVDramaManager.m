//
//  TVDramaManager.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "TVDramaManager.h"
#import "NSString+Hash.h"
#import "VideoModels.h"
#import "NSObject+Block.h"

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
    NSLog(@"TVDramaManager dealloc");
}

- (void)releaseHandlers
{
    self.requestHandler = nil;
}

// read property with videoGroupInCurrentThread
- (VideoGroup *)videoGroupInCurrentThread
{
    return [self.videoGroup MR_inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

- (Video *)playingVideo
{
    VideoGroup *videoGroup = [self videoGroupInCurrentThread];
    return [videoGroup videoAtSetNum:@(self.curSetNum)];
}

- (void)saveVideoInfoWithDuration:(CGFloat)duration
{
    if (duration == 0) {
        return;
    }
    
    Video *video = [self playingVideo];
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        Video *videoInContext = [video MR_inContext:localContext];
        videoInContext.duration = @(duration);
        
        if (self.playingURL.length > 0) {
            VideoChannelInfo *videoChannelInfo = [videoInContext videoChannelInfoAtWebURL:self.webURL];
            videoChannelInfo.videoSrc = self.playingURL;
        }
    }];
    
}

- (BOOL)loadLocalDramaInfo
{
    Video *video = [Video videoWithWebURL:self.webURL];
    if (video) {
        self.curSetNum = [video.setNum intValue];
        self.videoGroup = video.videoGroup;
        self.srcIndex = [video videoChannelInfoAtWebURL:self.webURL].srcIndex.integerValue;
        return YES;
    }
    return NO;
}

- (void)getDramaInfo:(TVDramaRequestType)requestType completionBlock:(void (^)(BOOL))completionBlock
{
    if (self.webURL.length == 0) {
        if (completionBlock)
            completionBlock(NO);
        return;
    }
    
    DefineWeakSelfBeforeBlock();
    [self.requestHandler tvDramaManager:self requestDramaInfoWithURL:self.webURL requestType:requestType completionBlock:^(VideoGroup *videoGroup, int srcIndex, int curSetNum) {
        [self performBlockInMainThread:^{
            DefineStrongSelfInBlock(sself);
            if (videoGroup) {
                sself.curSetNum = curSetNum;
                sself.srcIndex = srcIndex;
                sself.videoGroup = [videoGroup MR_inThreadContext];
                
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
        } afterDelay:0];
    }];
}

- (void)sniffVideoSource:(void (^)(BOOL success))completionBlock
{
    if (self.webURL.length == 0) {
        if (completionBlock)
            completionBlock(NO);
        return;
    }
    
    [self.requestHandler tvDramaManager:self sniffVideoSrcWithURL:self.webURL clarity:self.currentClarity src:[VideoGroup srcDescription:self.srcIndex] completionBlock:^(NSString *videoSrc, NSInteger clarityCount) {
        if (videoSrc.length > 0) {
            [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
                VideoChannelInfo *videoChannelInfo = [VideoChannelInfo videoChannelInfoWithURL:self.webURL inContext:localContext];
                videoChannelInfo.videoSrc = videoSrc;
            }];
            
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
    DefineWeakSelfBeforeBlock();
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        DefineStrongSelfInBlock(sself);
        
        VideoGroup *videoGroup = [sself.videoGroup MR_inContext:localContext];
        
        // Add one video object for non-drama video group
        if (![videoGroup isValidDrama]) {
            
            NSString *title = [videoGroup displayNameForSetNum:nil];
            if (title.length == 0) {
                title = sself.suggestedTitle;
                if (title.length == 0) {
                    title = [VideoGroup temporaryDisplayName];
                }
            }
            
            if (videoGroup == nil) {
                NSString *videoId = [sself generateVideoIdWithKey:sself.webURL];
                videoGroup = [VideoGroup videoGroupWithVideoId:videoId inContext:localContext];
                if (videoGroup == nil) {
                    // Need create a videoGroup for it
                    videoGroup = [VideoGroup MR_createInContext:localContext];
                    videoGroup.videoName = title;
                    videoGroup.videoId = videoId;
                    NSLog(@"Create VideoGroup[%@] for %@", videoId, sself.webURL);
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
                [videoGroup addVideosObject:updatedVideo];
            }
            updatedVideo.brief = title;
            
            VideoChannelInfo *videoChannelInfo = [updatedVideo videoChannelInfoAtWebURL:sself.webURL];
            if (videoChannelInfo == nil) {
                videoChannelInfo = [VideoChannelInfo MR_createInContext:localContext];
                [updatedVideo addVideoChannelInfosObject:videoChannelInfo];
            }
            
            videoChannelInfo.url = sself.webURL;
            if ([sself.webURL hasPrefix:@"file:"]) {
                // This is no-documented local video, such as from micro cloud
                // Such as: file://localhost/var/mobile/Applications/9EAE0502-52BC-4568-A6CB-D22465601BEC/Library/Caches/mtt/Videos/1%208.C%E8%AF%AD%E8%A8%8016-%E6%8C%87%E9%92%88%E7%BB%8F%E5%85%B8%E6%A1%88%E4%BE%8B(1).mp4
                
                NSURL *filePath = [NSURL URLWithString:sself.webURL];
                updatedVideo.path = [filePath relativePath];
            }
            sself.curSetNum = 0;
            sself.srcIndex = 0;
            sself.videoGroup = videoGroup;
        }
    }];

}

- (NSString *)generateVideoIdWithKey:(NSString *)key
{
    return [VideoGroup generateVideoIdForUnRecognizedWebURL:key];
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

- (void)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL requestType:(TVDramaRequestType)requestType completionBlock:(GetDramaInfoBlock)completionBlock
{
    __block BOOL hasSuccessed = NO;
    __block int remainingCallbackCount = self.handlers.count;
    for (id<TVDramaRequestHandler> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(tvDramaManager:requestDramaInfoWithURL:requestType:completionBlock:)]) {
            [handler tvDramaManager:manager requestDramaInfoWithURL:URL requestType:requestType completionBlock:^(VideoGroup *videoGroup, int srcIndex, int curSetNum) {
//                NSLog(@"[P2] requestDramaInfoWithURL  %d, %d, handler = %@", remainingCallbackCount, curSetNum, handler);
                BOOL success = videoGroup != nil;
                
                if (remainingCallbackCount <= 0) {
                    return;
                }
                
                if (success && !hasSuccessed) { // no success before yet, but success this time, should be callback with success
                    hasSuccessed = YES;
                    if (completionBlock) {
                        completionBlock(videoGroup, srcIndex, curSetNum);
                    }
                }
                else if (remainingCallbackCount == 1 && !hasSuccessed) { // the last handler callback and on success before yet
                    if (completionBlock) {
                        completionBlock(nil, 0, 0);
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

- (void)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL requestType:(TVDramaRequestType)requestType completionBlock:(GetDramaInfoBlock)completionBlock
{
    DefineWeakSelfBeforeBlock();
    if ([self.actualHandler respondsToSelector:@selector(tvDramaManager:requestDramaInfoWithURL:requestType:completionBlock:)]) {
        [self.actualHandler tvDramaManager:manager requestDramaInfoWithURL:URL requestType:requestType completionBlock:^(VideoGroup *videoGroup, int srcIndex, int curSetNum) {
//            NSLog(@"[P1] requestDramaInfoWithURL  %d, handler = %@", curSetNum, self.actualHandler);
            DefineStrongSelfInBlock(sself);
            if (videoGroup) {
                if (completionBlock) {
                    completionBlock(videoGroup, srcIndex, curSetNum);
                }
            }
            else if (sself.nextHandler) {
                [sself.nextHandler tvDramaManager:manager requestDramaInfoWithURL:URL requestType:requestType completionBlock:completionBlock];
            }
            else {
                if (completionBlock) {
                    completionBlock(nil, 0, 0);
                }
            }
        }];
    }
    else if (self.nextHandler) {
        [self.nextHandler tvDramaManager:manager requestDramaInfoWithURL:URL requestType:requestType completionBlock:completionBlock];
    }
    else {
        if (completionBlock) {
            completionBlock(nil, 0, 0);
        }
    }
}

- (void)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURL:(NSString *)URL clarity:(NSInteger)clarity src:(NSString *)src completionBlock:(void (^)(NSString *videoSrc, NSInteger clarityCount))completionBlock
{
    DefineWeakSelfBeforeBlock();
    if ([self.actualHandler respondsToSelector:@selector(tvDramaManager:sniffVideoSrcWithURL:clarity:src:completionBlock:)]) {
        [self.actualHandler tvDramaManager:manager sniffVideoSrcWithURL:URL clarity:clarity src:src completionBlock:^(NSString *videoSrc, NSInteger clarityCount) {
//            NSLog(@"[P1] sniffVideoSource %@, %d, handler = %@", videoSrc, clarityCount, self.actualHandler);
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
