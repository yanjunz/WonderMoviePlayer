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

@protocol BatMovieDownloaderDelegate <NSObject>
@optional
- (void)batMovieDownloaderDidAddAllTasks:(id<BatMovieDownloader>)downloader;
@end


@protocol BatMovieDownloader <NSObject>
@property (nonatomic, weak) id<BatMovieDownloaderDelegate> batMovieDownloaderDelegate;
- (void)batchDownloadURLs:(NSArray *)downloadURLs titles:(NSDictionary *)titles knownVideoSources:(NSDictionary *)knownVideoSources;
@end
