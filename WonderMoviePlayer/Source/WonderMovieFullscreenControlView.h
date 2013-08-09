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
    MovieControlStateDefault, // not started
    MovieControlStatePlaying,
    MovieControlStatePaused,
//    MovieControlStateBuffering,
    MovieControlStateEnded,
} MovieControlState;

typedef enum {
    MovieControlCommandPlay,
    MovieControlCommandPause,
    MovieControlCommandStop,
    MovieControlCommandReplay,
    MovieControlCommandSetProgress,
} MovieControlCommand;

@interface WonderMovieFullscreenControlView : UIView<MovieControlSource>
@property (nonatomic, assign) MovieControlState controlState;
@end
