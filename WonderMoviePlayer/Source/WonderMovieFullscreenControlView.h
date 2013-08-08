//
//  WonderMovieFullscreenControlView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MovieControlSource.h"

typedef enum {
    WonderMovieControlStateDefault, // not started
    WonderMovieControlStatePlaying,
    WonderMovieControlStatePaused,
    WonderMovieControlStateEnded,
} WonderMovieControlState;

@interface WonderMovieFullscreenControlView : UIView<MovieControlSource>
@property (nonatomic, assign) WonderMovieControlState controlState;
@end
