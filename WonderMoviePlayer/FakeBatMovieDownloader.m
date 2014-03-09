//
//  FakeBatMovieDownloader.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 28/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "FakeBatMovieDownloader.h"

@implementation FakeBatMovieDownloader
- (void)batchDownloadURLs:(NSArray *)downloadURLs titles:(NSDictionary *)titles knownVideoSources:(NSDictionary *)knownVideoSources clarity:(NSInteger)clarity
{
    NSLog(@"batchDownloadURL %@, %d", downloadURLs, clarity);
}
@end
