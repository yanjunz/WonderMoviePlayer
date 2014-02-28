//
//  MoviePlayerHandler.h
//  mtt
//
//  Created by Zhuang Yanjun on 13-9-9.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MoviePlayerHandler <NSObject>
@property (nonatomic, copy) void(^crossScreenBlock)();
@property (nonatomic, copy) void(^exitBlock)();
#ifndef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
@property (nonatomic, copy) void(^downloadBlock)();
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER

@property (nonatomic, copy) void(^myVideoBlock)();
@end
