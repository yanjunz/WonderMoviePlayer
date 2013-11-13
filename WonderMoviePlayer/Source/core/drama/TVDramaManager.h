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

@protocol TVDramaManagerDelegate;

@interface TVDramaManager : NSObject
@property (nonatomic, assign) id<TVDramaManagerDelegate> delegate;
@property (nonatomic, copy) NSString *webURL;
@property (nonatomic, retain) VideoGroup *videoGroup;
@property (nonatomic) int curSetNum;
- (BOOL)getCurrentSectionDramaInfo;
- (BOOL)getPreviousSectionDramaInfo;
- (BOOL)getNextSectionDramaInfo;
- (BOOL)sniffVideoSource;
@end

@protocol TVDramaManagerDelegate <NSObject>

- (VideoGroup *)tvDramaManager:(TVDramaManager *)manager requestCurrentSectionDramaInfoWithURL:(NSString *)URL curSetNum:(int *)curSetNumPtr;
- (VideoGroup *)tvDramaManager:(TVDramaManager *)manager requestPreviousSectionDramaInfoWithURL:(NSString *)URL curSetNum:(int *)curSetNumPtr;
- (VideoGroup *)tvDramaManager:(TVDramaManager *)manager requestNextSectionDramaInfoWithURL:(NSString *)URL curSetNum:(int *)curSetNumPtr;
- (NSDictionary *)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURLs:(NSArray *)URLs;

@end