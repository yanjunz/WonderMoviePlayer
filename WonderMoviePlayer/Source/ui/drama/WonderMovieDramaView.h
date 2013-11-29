//
//  WonderMovieDramaView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/14/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVDramaManager.h"
#import "DramaTableView.h"

@class WonderMovieDramaView;

@protocol WonderMovieDramaViewDelegate <NSObject>

- (void)wonderMovieDramaView:(WonderMovieDramaView *)dramaView didSelectSetNum:(int)setNum;

@end

@interface WonderMovieDramaView : UIView<UITableViewDataSource, DramaTableViewDelegate>
@property (nonatomic, assign) id<WonderMovieDramaViewDelegate> delegate;
@property (nonatomic, retain) TVDramaManager *tvDramaManager;
@property (nonatomic, retain) DramaTableView *tableView;
@property (nonatomic, retain) UIView *errorView;
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic) int playingSetNum;
- (void)reloadData;
@end
