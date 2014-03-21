//
//  Video+Additions.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "Video.h"

@interface Video (Additions)

+ (instancetype)videoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum;
+ (instancetype)videoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum inContext:(NSManagedObjectContext *)context;
+ (instancetype)videoWithWebURL:(NSString *)URL;
+ (instancetype)videoWithPath:(NSString *)path;
+ (instancetype)videoWithPath:(NSString *)path inContext:(NSManagedObjectContext *)context;

- (VideoChannelInfo *)videoChannelInfoAtSrcIndex:(NSInteger)srcIndex;
- (VideoChannelInfo *)videoChannelInfoAtWebURL:(NSString *)webURL;
- (VideoChannelInfo *)bestVideoChannelInfo;

- (NSString *)displayName;

- (BOOL)hasLocalFile;
- (BOOL)isPureLocalFile; // indicate if it is pure local file without any related web resource
- (NSString *)localFilePathChecked;
- (void)saveCreateTimeInContext:(NSManagedObjectContext *)context;
- (void)saveCompletedTimeInContext:(NSManagedObjectContext *)context;
- (void)clearTimeInContext:(NSManagedObjectContext *)context;

- (void)saveVideoSrc:(NSString *)videoSrc forSrcIndex:(NSInteger)srcIndex;
- (NSString *)webURLAtSrcIndex:(NSInteger)srcIndex;
@end
