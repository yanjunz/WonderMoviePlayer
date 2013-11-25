//
//  MovieDownloader.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/25/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MovieDownloader;

@protocol MovieDownloaderDelegate <NSObject>
@optional
- (void)movieDownloaderStarted:(id<MovieDownloader>)downloader;
- (void)movieDownloaderPaused:(id<MovieDownloader>)downloader;
- (void)movieDownloader:(id<MovieDownloader>)downloader setProgress:(CGFloat)progress;
- (void)movieDownloaderFinished:(id<MovieDownloader>)downloader;
@end

@protocol MovieDownloader <NSObject>
@required
@property (nonatomic, assign) id<MovieDownloaderDelegate> movieDownloaderDelegate;

- (void)mdStartDownload:(NSURL *)downloadURL;
- (void)mdPause;
- (void)mdContinue;

- (BOOL)mdHasTask:(NSURL *)downloadURL;
- (BOOL)mdIsDownaloading:(NSURL *)downloadURL;
- (BOOL)mdIsFinished:(NSURL *)downloadURL;
- (BOOL)mdIsPaused:(NSURL *)downloadURL;
@end
