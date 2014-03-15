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

- (VideoChannelInfo *)videoChannelInfoAtSrcIndex:(NSInteger)srcIndex;
- (VideoChannelInfo *)videoChannelInfoAtWebURL:(NSString *)webURL;
- (VideoChannelInfo *)bestVideoChannelInfo;

- (NSString *)displayName;

- (BOOL)hasLocalFile;
- (void)saveVideoSrc:(NSString *)videoSrc forSrcIndex:(NSInteger)srcIndex;
- (NSString *)webURLAtSrcIndex:(NSInteger)srcIndex;
@end
