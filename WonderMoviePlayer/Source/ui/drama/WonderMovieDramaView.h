//
//  WonderMovieDramaView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/14/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVDramaManager.h"

@interface WonderMovieDramaView : UIView
@property (nonatomic, retain) TVDramaManager *tvDramaManager;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIView *errorView;
@property (nonatomic, retain) UIView *loadingView;

- (void)reloadData;
@end
