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
@property (nonatomic, retain) NSURL *downloadURL;
@property (nonatomic, readonly) BOOL isBinded;

- (void)mdBindDownloadURL:(NSURL *)downloadURL delegate:(id<MovieDownloaderDelegate>)delegate;
- (void)mdUnBind;

- (void)mdStart;
- (void)mdPause;
- (void)mdContinue;

- (MovieDownloadState)mdQueryDownloadState:(NSURL *)downloadURL;
@end
