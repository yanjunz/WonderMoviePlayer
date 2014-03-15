//
//  VideoChannelInfo+Additions.h
//  mtt
//
//  Created by Zhuang Yanjun on 14/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "VideoChannelInfo.h"

@interface VideoChannelInfo (Additions)

+ (instancetype)videoChannelInfoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum srcIndex:(NSInteger)srcIndex;
+ (instancetype)videoChannelInfoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum srcIndex:(NSInteger)srcIndex inContext:(NSManagedObjectContext *)context;
+ (instancetype)videoChannelInfoWithURL:(NSString *)URL;
+ (instancetype)videoChannelInfoWithURL:(NSString *)URL inContext:(NSManagedObjectContext *)context;
+ (instancetype)videoChannelInfoWithVideoSrc:(NSString *)videoSrc;
+ (instancetype)videoChannelInfoWithVideoSrc:(NSString *)videoSrc inContext:(NSManagedObjectContext *)context;
@end
