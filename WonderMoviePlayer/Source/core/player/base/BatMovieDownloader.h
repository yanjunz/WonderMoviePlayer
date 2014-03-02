//
//  BatMovieDownloader.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 28/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MovieDownloader.h"

@protocol BatMovieDownloader;

@protocol BatMovieDownloaderDataSource <NSObject>
@optional
- (NSString *)titleForBatMovieDownloader:(id<BatMovieDownloader>)downloader downloadURL:(NSString *)downloadURL;
- (NSString *)videoSourceForBatMovieDownloader:(id<BatMovieDownloader>)downloader downloadURL:(NSString *)downloadURL;
@end

@protocol BatMovieDownloader <NSObject>
@property (nonatomic, weak) id<BatMovieDownloaderDataSource> batMovieDownloaderDataSource;
- (void)batchDownloadURLs:(NSArray *)downloadURLs;
- (NSArray *)batchQueryDownloadStates:(NSArray *)downloadURLs;

@end
