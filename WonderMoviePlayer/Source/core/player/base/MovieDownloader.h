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
- (void)movieDownloaderContinued:(id<MovieDownloader>)downloader;
- (void)movieDownloader:(id<MovieDownloader>)downloader setProgress:(CGFloat)progress;
- (void)movieDownloaderFinished:(id<MovieDownloader>)downloader;
@end

@protocol MovieDownloaderDataSource <NSObject>
@optional
- (NSString *)titleForMovieDownloader:(id<MovieDownloader>)downloader;
@end

typedef enum {
    MovieDownloadStateNotDownload,
    MovieDownloadStatePaused,
    MovieDownloadStateDownloading,
    MovieDownloadStateFinished,
    MovieDownloadStateFailed,
} MovieDownloadState;

@protocol MovieDownloader <NSObject>
@required
@property (nonatomic, assign) id<MovieDownloaderDelegate> movieDownloaderDelegate;
@property (nonatomic, assign) id<MovieDownloaderDataSource> movieDownloaderDataSource;
@property (nonatomic, retain) NSURL *downloadURL;
@property (nonatomic, readonly) BOOL isBinded;

- (void)mdBindDownloadURL:(NSURL *)downloadURL delegate:(id<MovieDownloaderDelegate>)delegate dataSource:(id<MovieDownloaderDataSource>)dataSource;
- (void)mdUnBind;

- (BOOL)mdStart;
- (BOOL)mdPause;
- (BOOL)mdContinue;

- (MovieDownloadState)mdQueryDownloadState:(NSURL *)downloadURL;
@end
