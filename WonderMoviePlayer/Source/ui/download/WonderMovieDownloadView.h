//
//  WonderMovieDownloadView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 28/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVDramaManager.h"
#import "DramaTableView.h"

@class WonderMovieDownloadView;
@protocol WonderMovieDownloadViewDelegate <NSObject>

- (void)wonderMovieDownloadViewDidCancel:(WonderMovieDownloadView *)downloadView;
- (void)wonderMovieDownloadView:(WonderMovieDownloadView *)downloadView didDownloadVideos:(NSArray *)videos;
- (void)wonderMovieDownloadView:(WonderMovieDownloadView *)downloadView didChangeSelectedVideos:(NSArray *)videos;

@end

@interface WonderMovieDownloadView : UIView<UITableViewDataSource, DramaTableViewDelegate>
@property (nonatomic, weak) id<WonderMovieDownloadViewDelegate> delegate;
@property (nonatomic, strong) TVDramaManager *tvDramaManager;
@property (nonatomic, strong) DramaTableView *tableView;
@property (nonatomic, strong) UIView *errorView;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic) int playingSetNum;
@property (nonatomic) BOOL supportBatchDownload; // unable to batch download if the website is not supported by sniffer
- (void)reloadData;

- (void)scrollToThePlayingOne;
- (void)cancel;
- (void)confirm;
@end
