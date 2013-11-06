//
//  WonderMovieFullscreenControlView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_MOVIE_PLAYER

#import <UIKit/UIKit.h>
#import "MovieControlSource.h"
#import "WonderMovieInfoView.h"

@interface WonderMovieFullscreenControlView : UIView<MovieControlSource>
@property (nonatomic, assign) BOOL autoPlayWhenStarted;
@property (nonatomic, assign) BOOL nextEnabled;           // set to show next button
@property (nonatomic, assign) BOOL downloadEnabled;
@property (nonatomic, assign) BOOL crossScreenEnabled;
@property (nonatomic, retain) WonderMovieInfoView *infoView;

- (id)initWithFrame:(CGRect)frame autoPlayWhenStarted:(BOOL)autoPlayWhenStarted nextEnabled:(BOOL)nextEnabled downloadEnabled:(BOOL)downloadEnabled crossScreenEnabled:(BOOL)crossScreenEnabled;

- (void)installGestureHandlerForParentView;
- (CGRect)suggestedInfoViewFrame;
@end

#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER
