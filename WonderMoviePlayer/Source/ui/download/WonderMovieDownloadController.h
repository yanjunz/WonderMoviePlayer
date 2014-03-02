//
//  WonderMovieDownloadController.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 2/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WonderMovieDownloadView.h"

@class TVDramaManager;

@interface WonderMovieDownloadController : UIViewController<WonderMovieDownloadViewDelegate>
@property (nonatomic, strong) WonderMovieDownloadView *downloadView;
@property (nonatomic, weak) id<WonderMovieDownloadViewDelegate> downloadViewDelegate;

- (id)initWithURL:(NSString *)URL;
- (id)initWithTVDramaManager:(TVDramaManager *)tvDramaManager;
@end
