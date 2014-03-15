//
//  BaseMoviePlayer.h
//  mtt
//
//  Created by Zhuang Yanjun on 13-9-16.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "MoviePlayerHandler.h"
#import "MovieControlSource.h"
#import "MovieDownloader.h"
#import "BatMovieDownloader.h"
#import "MovieInfoObtainer.h"

@protocol BaseMoviePlayerDelegate;

@protocol BaseMoviePlayer <
MovieControlSourceDelegate, MoviePlayerHandler, MovieInfoObtainerDelegate

#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
, MovieDownloaderDelegate, MovieDownloaderDataSource
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER

#ifdef MTT_TWEAK_BAT_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
, BatMovieDownloaderDelegate
#endif // MTT_TWEAK_BAT_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
>
@property (nonatomic, retain) id<MovieControlSource> controlSource;

// Downloader
#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
@property (nonatomic, retain) id<MovieDownloader> movieDownloader;
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER

#ifdef MTT_TWEAK_BAT_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
@property (nonatomic, retain) id<BatMovieDownloader> batMovieDownloader;
#endif // MTT_TWEAK_BAT_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER


@property (nonatomic, weak) id<BaseMoviePlayerDelegate> delegate;

//- (void)playMovieStream:(NSURL *)movieURL fromProgress:(CGFloat)progress;
//- (void)playMovieStream:(NSURL *)movieURL fromTime:(CGFloat)time;
- (void)playWithMovieObtainer:(id<MovieInfoObtainer>)movieInfoObtainer;

@optional
- (UIImage *)screenShot:(CGFloat)progress size:(CGSize)size;
- (CGFloat)playedProgress;
@end

@protocol BaseMoviePlayerDelegate <NSObject>
@optional
- (void)baseMoviePlayerDidStart:(id<BaseMoviePlayer>)baseMoviePlayer;
- (void)baseMoviePlayerDidEnd:(id<BaseMoviePlayer>)baseMoviePlayer;
- (void)baseMoviePlayer:(id<BaseMoviePlayer>)baseMoviePlayer didGetVideoGroup:(VideoGroup *)videoGroup;
@end
