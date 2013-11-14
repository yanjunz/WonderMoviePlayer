//
//  TVDramaManager.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VideoGroup;
typedef void (^GetDramaInfoBlock)(VideoGroup *videoGroup, int setNum);
typedef void (^FailedBlock)();

typedef enum {
    TVDramaRequestTypeCurrent,
    TVDramaRequestTypePrevious,
    TVDramaRequestTypeNext,
} TVDramaRequestType;

@protocol TVDramaManagerDelegate;

@interface TVDramaManager : NSObject
@property (nonatomic, assign) id<TVDramaManagerDelegate> delegate;
@property (nonatomic, copy) NSString *webURL;
@property (nonatomic, retain) VideoGroup *videoGroup;
@property (nonatomic) int curSetNum;

- (BOOL)getDramaInfo:(TVDramaRequestType)requestType;
- (BOOL)sniffVideoSource;
@end

@protocol TVDramaManagerDelegate <NSObject>

- (VideoGroup *)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL curSetNum:(int *)curSetNumPtr requestType:(TVDramaRequestType)requestType;
- (NSDictionary *)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURLs:(NSArray *)URLs;

@end