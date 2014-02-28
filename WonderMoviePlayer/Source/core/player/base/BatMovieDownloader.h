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

@end

@protocol BatMovieDownloader <NSObject>

- (void)batchDownloadURLs:(NSArray *)downloadURLs;
- (NSArray *)batchQueryDownloadStates:(NSArray *)downloadURLs;

@end
