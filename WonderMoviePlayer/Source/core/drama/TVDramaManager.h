//
//  TVDramaManager.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VideoGroup;
@class Video;
@class ResponsibilityChainTVDramaRequestHandler;

typedef void (^GetDramaInfoBlock)(VideoGroup *videoGroup, int setNum);
typedef void (^FailedBlock)();

typedef enum {
    TVDramaRequestTypeCurrent,
    TVDramaRequestTypePrevious,
    TVDramaRequestTypeNext,
} TVDramaRequestType;

@protocol TVDramaRequestHandler;

@interface TVDramaManager : NSObject
@property (nonatomic, copy) NSString *webURL;
@property (nonatomic, copy) NSString *playingURL;
@property (nonatomic, strong) VideoGroup *videoGroup;
@property (nonatomic, assign) int curSetNum;
@property (nonatomic, assign) NSInteger clarityCount;
@property (nonatomic, assign) NSInteger currentClarity;

@property (nonatomic, strong) ResponsibilityChainTVDramaRequestHandler *requestHandler;

- (VideoGroup *)videoGroupInCurrentThread;
- (Video *)playingVideo;
- (void)getDramaInfo:(TVDramaRequestType)requestType completionBlock:(void (^)(BOOL success))completionBlock;
- (void)sniffVideoSource:(void (^)(BOOL success))completionBlock;
- (BOOL)hasNext;
@end


@protocol TVDramaRequestHandler <NSObject>
@optional
- (void)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL requestType:(TVDramaRequestType)requestType completionBlock:(void (^)(VideoGroup *videoGroup, int curSetNum))completionBlock;

- (void)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURL:(NSString *)URL clarity:(NSInteger)clarity src:(NSString *)src completionBlock:(void (^)(NSString *videoSrc, NSInteger clarityCount))completionBlock;
@end

/**
 * Use Composite Design Pattern for TVDramaRequestHandler
 * It is a bit complicated since the handler is not blocked but asynchronized
 **/
@interface CompositeTVDramaRequestHandler : NSObject<TVDramaRequestHandler>
@property (nonatomic, strong) NSMutableArray *handlers;

+ (instancetype)handlerWithHandlers:(NSArray *)handlers;
- (void)addHandler:(id<TVDramaRequestHandler>)handler;
- (void)removeHandler:(id<TVDramaRequestHandler>)hanlder;
@end

/**
 * Use Chain of Responsibility Design Pattern for TVDramaRequestHandler
 * Since there is priority for handler, so this pattern is needed to handle in order
 **/
@interface ResponsibilityChainTVDramaRequestHandler : NSObject<TVDramaRequestHandler>
@property (nonatomic, strong) ResponsibilityChainTVDramaRequestHandler *nextHandler;
@property (nonatomic, strong) id<TVDramaRequestHandler> actualHandler;

+ (instancetype)handlerWithActualHandler:(id<TVDramaRequestHandler>)actualHandler
                             nextHandler:(ResponsibilityChainTVDramaRequestHandler *)nextHandler;
@end