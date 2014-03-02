//
//  WonderMovieDownloadController.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 2/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WonderMovieDownloadView.h"
#import "BatMovieDownloader.h"

@class TVDramaManager;

@interface WonderMovieDownloadController : UIViewController<WonderMovieDownloadViewDelegate>
@property (nonatomic, strong) TVDramaManager *tvDramaManager;

@property (nonatomic, weak) id<WonderMovieDownloadViewDelegate> downloadViewDelegate;
@property (nonatomic, strong) id<BatMovieDownloader> batMovieDownloader;

@property (nonatomic, strong) WonderMovieDownloadView *downloadView;
@property (nonatomic, strong) UILabel *availableSpaceLabel;

- (id)initWithURL:(NSString *)URL;
- (id)initWithTVDramaManager:(TVDramaManager *)tvDramaManager;
@end
