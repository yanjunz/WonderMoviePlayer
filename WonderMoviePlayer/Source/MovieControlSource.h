//
//  MovieControlSource.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * delegate will not be notified if functions such as play, pause, etc. were called.
 * delegate will only be notified when MovieControlSource internally trigger play/pause and other video operations.
 */


@protocol MovieControlSourceDelegate;

@protocol MovieControlSource <NSObject>
@required
// Video operations
- (void)play;
- (void)pause;
- (void)resume;
- (void)replay;
- (void)setProgress:(CGFloat)progress;
- (void)exit;

@optional

// Auxiliary Utils
- (void)startToDownload;
- (void)pauseDownload;
- (void)lockScreen;

// Set movie screen state
- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;

// Set system state
- (void)setBrightness:(CGFloat)brightness;
- (void)setVolumne:(CGFloat)volumne;

// Update play time info
- (void)setPlaybackTime:(NSTimeInterval)playbackTime;
- (void)setPlaybackDuration:(NSTimeInterval)playbackDuration;


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