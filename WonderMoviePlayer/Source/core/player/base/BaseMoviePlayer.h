//
//  BaseMoviePlayer.h
//  mtt
//
//  Created by Zhuang Yanjun on 13-9-16.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoviePlayerHandler.h"
#import "MovieControlSource.h"
#import "MovieDownloader.h"

@protocol BaseMoviePlayer <MovieControlSourceDelegate, MoviePlayerHandler, MovieDownloaderDelegate>
@property (nonatomic, retain) id<MovieControlSource> controlSource;
@property (nonatomic, retain) id<MovieDownloader> movieDownloader;
@property (nonatomic, assign) BOOL isLiveCast;
@end
