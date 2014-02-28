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

@protocol BaseMoviePlayerDelegate;

@protocol BaseMoviePlayer <
MovieControlSourceDelegate, MoviePlayerHandler
, MovieDownloaderDelegate, MovieDownloaderDataSource
>
@property (nonatomic, retain) id<MovieControlSource> controlSource;
@property (nonatomic, retain) id<MovieDownloader> movieDownloader;
@property (nonatomic, weak) id<BaseMoviePlayerDelegate> delegate;

- (void)playMovieStream:(NSURL *)movieURL fromProgress:(CGFloat)progress;
- (void)playMovieStream:(NSURL *)movieURL fromTime:(CGFloat)time;

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