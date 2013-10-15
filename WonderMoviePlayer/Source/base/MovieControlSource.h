//
//  MovieControlSource.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//
#ifdef MTT_FEATURE_WONDER_MOVIE_PLAYER

#import <Foundation/Foundation.h>


typedef enum {
    MovieControlStateDefault, // not started
    MovieControlStatePlaying,
    MovieControlStatePaused,
    MovieControlStateBuffering,
    MovieControlStateEnded,
} MovieControlState;

typedef enum {
    MovieControlCommandPlay,
    MovieControlCommandPause,
    MovieControlCommandEnd,
    MovieControlCommandReplay,
    MovieControlCommandSetProgress,
    MovieControlCommandBuffer,
    MovieControlCommandUnbuffer,
} MovieControlCommand;

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
- (void)buffer;
- (void)unbuffer;
- (void)end;

// Resource install & uninstall
- (void)installControlSource;
- (void)uninstallControlSource;

@optional

// Auxiliary Utils
- (void)startToDownload;
- (void)finishDownload;
- (void)pauseDownload;
- (void)lockScreen;
- (void)setBufferProgress:(CGFloat)progress;

// Set movie screen state
- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;

// Set system state
- (void)setBrightness:(CGFloat)brightness;
- (void)setVolume:(CGFloat)volume;

// Update play time info
- (void)setPlaybackTime:(NSTimeInterval)playbackTime;
- (void)setPlayableDuration:(NSTimeInterval)playableDuration;
- (void)setDuration:(NSTimeInterval)duration;

// Return the length of time control such as a progressbar, used for calcuate the interval for progress timer
- (CGFloat)getTimeControlWidth;

@property (nonatomic, assign) BOOL isLiveCast;

@required
@property (nonatomic, assign) MovieControlState controlState;
@property (nonatomic, assign) id<MovieControlSourceDelegate> delegate;
@end

@protocol MovieControlSourceDelegate <NSObject>
@required
- (void)movieControlSourcePlay:(id<MovieControlSource>)source;
- (void)movieControlSourcePause:(id<MovieControlSource>)source;
- (void)movieControlSourceResume:(id<MovieControlSource>)source;
- (void)movieControlSourceReplay:(id<MovieControlSource>)source;
- (void)movieControlSourceBeginChangeProgress:(id<MovieControlSource>)source;
- (void)movieControlSource:(id<MovieControlSource>)source endChangeProgress:(CGFloat)progress;
- (void)movieControlSource:(id<MovieControlSource>)source setProgress:(CGFloat)progress;
- (void)movieControlSourceExit:(id<MovieControlSource>)source;

@optional
- (void)movieControlSourceBuffer:(id<MovieControlSource>)source;
- (void)movieControlSourceUnbuffer:(id<MovieControlSource>)source;
- (void)movieControlSource:(id<MovieControlSource>)source setFullscreen:(BOOL)fullscreen;
- (void)movieControlSourceOnCrossScreen:(id<MovieControlSource>)source;
- (void)movieControlSource:(id<MovieControlSource>)source lock:(BOOL)lock;

- (void)movieControlSource:(id<MovieControlSource>)source increaseBrightness:(CGFloat)brightness;
- (void)movieControlSource:(id<MovieControlSource>)source increaseVolume:(CGFloat)volume;
- (void)movieControlSourceOnDownload:(id<MovieControlSource>)source;
@end

#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER
