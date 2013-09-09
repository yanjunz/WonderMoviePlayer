//
//  WonderAVPlayerView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-16.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_AVMOVIE_PLAYER

#import <UIKit/UIKit.h>

@class AVPlayerLayer;

@interface WonderAVPlayerView : UIView
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

- (void)setVideoFillMode:(NSString *)fillMode;
@end

#endif // MTT_FEATURE_WONDER_AVMOVIE_PLAYER
