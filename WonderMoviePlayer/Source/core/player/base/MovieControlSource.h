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
    MovieControlStatePreparing, // prepare to play next
    MovieControlStateErrored,
} MovieControlState;

typedef enum {
    MovieControlCommandPlay,
    MovieControlCommandPause,
    MovieControlCommandEnd,
    MovieControlCommandReplay,
    MovieControlCommandSetProgress,
    MovieControlCommandBuffer,
    MovieControlCommandUnbuffer,
    MovieControlCommandPlayNext,
    MovieControlCommandError,
} MovieControlCommand;

typedef enum {
    LiveCastStateNotCheckYet,   // live cast state is not checked yet, default value
    LiveCastStateNo,            // is not live cast
    LiveCastStateYes,           // is live cast
} LiveCastState;

/**
 * delegate will not be notified if functions such as play, pause, etc. were called.
 * delegate will only be notified when MovieControlSource internally trigger play/pause and other video operations.
 */

@protocol MovieControlSourceDelegate;
@protocol VideoHistoryOperator;
@protocol VideoBookmarkOperator;
@class TVDramaManager;
@class Video;
@class VideoGroup;

@protocol MovieControlSource <NSObject>
@required
// Video operations
- (void)prepareToPlay;
- (void)play;
- (void)pause;
- (void)resume;
- (void)replay;
- (void)setProgress:(CGFloat)progress;
- (void)buffer;
- (void)unbuffer;
- (void)end;
- (void)playNext;
- (void)error:(NSString *)msg;

// Resource install & uninstall
- (void)installControlSource;
- (void)uninstallControlSource;
- (void)resetState;

@optional

// Auxiliary Utils
- (void)startToDownload;
- (void)finishDownload;
- (void)pauseDownload;
- (void)continueDownload;
- (void)setDownloadProgress:(CGFloat)progress;

- (void)lockScreen;

- (void)setBufferProgress:(CGFloat)progress;
- (void)setBufferTitle:(NSString *)title;
- (void)resetBufferTitle;

- (void)showToast:(NSString *)toast;

// Set movie screen state
- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;

// Update play time info
- (void)setPlaybackTime:(NSTimeInterval)playbackTime;
- (void)setPlayableDuration:(NSTimeInterval)playableDuration;
- (void)setDuration:(NSTimeInterval)duration;

// Return the length of time control such as a progressbar, used for calcuate the interval for progress timer
- (CGFloat)getTimeControlWidth;
- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle;

@property (nonatomic, assign) LiveCastState liveCastState;
@property (nonatomic, copy) NSArray *resolutions;
@property (nonatomic) int selectedResolutionIndex;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *subtitle;

@property (nonatomic, assign) BOOL alertCopyrightInsteadOfDownload;

@property (nonatomic, strong) TVDramaManager *tvDramaManager;
@property (nonatomic, strong) id<VideoBookmarkOperator> bookmarkOperator;
@property (nonatomic, strong) id<VideoHistoryOperator> historyOperator;

// system state
@property (nonatomic, assign) CGFloat brightness;
@property (nonatomic, assign) CGFloat volume;
@required
@property (nonatomic, assign) MovieControlState controlState;
@property (nonatomic, weak) id<MovieControlSourceDelegate> delegate;
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
- (void)movieControlSourceEnd:(id<MovieControlSource>)source;
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

- (void)movieControlSourceSwitchVideoGravity:(id<MovieControlSource>)source;
- (void)movieControlSource:(id<MovieControlSource>)source showControlView:(BOOL)show;
- (void)movieControlSource:(id<MovieControlSource>)source didChangeResolution:(NSString *)resolution;

// Drama
- (void)movieControlSourceDramaLoadFinished:(id<MovieControlSource>)source;
- (void)movieControlSourceWillPlayNext:(id<MovieControlSource>)source;
- (void)movieControlSource:(id<MovieControlSource>)source didPlayNext:(NSString *)videoSource;
- (void)movieControlSourceFailToPlayNext:(id<MovieControlSource>)source;

- (void)movieControlSourceDidError:(id<MovieControlSource>)source;

- (void)movieControlSourceHandleError:(id<MovieControlSource>)source;
@end

#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER
