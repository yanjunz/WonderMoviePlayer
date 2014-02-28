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

@interface WonderMovieDownloadView : UIView<UITableViewDataSource, DramaTableViewDelegate>
@property (nonatomic, strong) TVDramaManager *tvDramaManager;
@property (nonatomic, strong) DramaTableView *tableView;
@property (nonatomic, strong) UIView *errorView;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic) int playingSetNum;
@end
