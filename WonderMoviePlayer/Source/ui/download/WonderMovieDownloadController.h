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

@interface WonderMovieDownloadController : CustomBaseViewController<WonderMovieDownloadViewDelegate> {
    int _currentClarity;
}

@property (nonatomic, strong) TVDramaManager *tvDramaManager;
@property (nonatomic, strong) id<BatMovieDownloader> batMovieDownloader;

@property (nonatomic, strong) WonderMovieDownloadView *downloadView;
@property (nonatomic, strong) UILabel *availableSpaceLabel;
@property (nonatomic, strong) UIButton *clarityButton;
@property (nonatomic, copy) NSArray *resolutions;

- (id)initWithTVDramaManager:(TVDramaManager *)tvDramaManager batMovieDownloader:(id<BatMovieDownloader>)batMovieDownloader;
- (void)setSupportBatchDownload:(BOOL)supportBatchDownload;

- (IBAction)onClickCancel:(id)sender;
- (IBAction)onClickDownload:(id)sender;
- (IBAction)onClickClarity:(id)sender;

- (void)selectClarity:(NSInteger)clarity;

@end
