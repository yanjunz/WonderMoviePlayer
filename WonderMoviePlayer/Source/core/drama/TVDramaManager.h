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
@property (nonatomic, strong) VideoGroup *videoGroup;
@property (nonatomic) int curSetNum;

- (void)addRequestHandler:(id<TVDramaRequestHandler>)handler;
- (void)removeRequestHandler:(id<TVDramaRequestHandler>)handler;

- (VideoGroup *)videoGroupInCurrentThread;
- (Video *)playingVideo;
- (BOOL)getDramaInfo:(TVDramaRequestType)requestType;
- (void)getDramaInfo:(TVDramaRequestType)requestType completionBlock:(void (^)(BOOL success))completionBlock;
- (BOOL)sniffVideoSource;
- (void)sniffVideoSource:(void (^)(BOOL success))completionBlock;
- (BOOL)hasNext;
@end


@protocol TVDramaRequestHandler <NSObject>
@optional
- (VideoGroup *)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL curSetNum:(int *)curSetNumPtr requestType:(TVDramaRequestType)requestType;
- (NSString *)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURL:(NSString *)URL src:(NSString *)src;

- (void)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL requestType:(TVDramaRequestType)requestType completionBlock:(void (^)(VideoGroup *videoGroup, int curSetNum))completionBlock;

- (void)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURL:(NSString *)URL src:(NSString *)src completionBlock:(void (^)(NSString *videoSrc))completionBlock;
@end