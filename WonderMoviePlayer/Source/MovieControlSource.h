//
//  MovieControlSource.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MovieControlSourceDelegate;

@protocol MovieControlSource <NSObject>
@required
- (void)play;
- (void)pause;
- (void)resume;
- (void)replay;
- (void)setProgress:(CGFloat)progress;
- (void)exit;

@optional
- (void)startToDownload;
- (void)pauseDownload;
- (void)lockScreen;
- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;
- (void)setBrightness:(CGFloat)brightness;
- (void)setVolumne:(CGFloat)volumne;

@required
@property (nonatomic, assign) id<MovieControlSourceDelegate> delegate;
@end

@protocol MovieControlSourceDelegate <NSObject>
@required
- (void)movieControlSourcePlay:(id<MovieControlSource>)source;
- (void)movieControlSourcePause:(id<MovieControlSource>)source;
- (void)movieControlSourceResume:(id<MovieControlSource>)source;
- (void)movieControlSourceReplay:(id<MovieControlSource>)source;
- (void)movieControlSource:(id<MovieControlSource>)source setProgress:(CGFloat)progress;
- (void)movieControlSourceExit:(id<MovieControlSource>)source;

@end