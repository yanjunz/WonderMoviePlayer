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
@property (nonatomic, weak) id<WonderMovieDramaViewDelegate> delegate;
@property (nonatomic, strong) TVDramaManager *tvDramaManager;
@property (nonatomic, strong) DramaTableView *tableView;
@property (nonatomic, strong) UIView *errorView;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic) int playingSetNum;
- (void)reloadData;
- (void)scrollToThePlayingOne;
@end
