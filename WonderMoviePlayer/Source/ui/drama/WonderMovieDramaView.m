//
//  WonderMovieDramaView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/14/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "WonderMovieDramaView.h"
#import "UIView+Sizes.h"
#import "NSObject+Block.h"

#define kDramaHeaderViewHeight 44

@implementation WonderMovieDramaView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, kDramaHeaderViewHeight)];
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        headerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5]; // FIXME
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, headerView.width - 20, headerView.height)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.text = NSLocalizedString(@"剧集列表", nil);
        [headerView addSubview:label];
        [self addSubview:label];
        [label release];
        [headerView release];
    }
    return self;
}

- (void)dealloc
{
    self.tvDramaManager = nil;
    self.tableView = nil;
    self.errorView = nil;
    self.loadingView = nil;
    [super dealloc];
}

- (void)reloadData
{
    if (self.tvDramaManager.videoGroup == nil) {
        [self.tableView removeFromSuperview];
        [self addSubview:self.loadingView];
        [self bringSubviewToFront:self.loadingView];
        [self loadCurrentSection];
    }
    else {
        [self.tableView reloadData];
    }
}

- (UIView *)loadingView
{
    if (_loadingView == nil) {
        UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight)];
        loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        loadingView.backgroundColor = [UIColor clearColor];
        UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        loadingIndicator.center = CGPointMake(CGRectGetMidX(loadingView.bounds), CGRectGetMidY(loadingView.bounds));
        [loadingView addSubview:loadingIndicator];
        [loadingIndicator startAnimating];
        [loadingIndicator release];
        _loadingView = loadingView;
    }
    return _loadingView;
}

- (UIView *)errorView
{
    if (_errorView == nil) {
        UIView *errorView = [[UIView alloc] initWithFrame:CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight)];
        errorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        errorView.backgroundColor = [UIColor clearColor];
        UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        retryButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [retryButton setTitle:NSLocalizedString(@"无法获取，请重试", nil) forState:UIControlStateNormal];
        [retryButton addTarget:self action:@selector(onClickRetry:) forControlEvents:UIControlEventTouchUpInside];
        retryButton.frame = errorView.bounds;
        [errorView addSubview:retryButton];
        _errorView = errorView;
    }
    return _errorView;
}

- (void)loadCurrentSection
{
    [self performBlockInBackground:^{
        BOOL ret = [self.tvDramaManager getDramaInfo:TVDramaRequestTypeCurrent];
        [self performBlock:^{
            if (ret) {
                [self finishCurrentSectionLoad];
            }
            else {
                [self showErrorView];
            }
        } afterDelay:0];
    }];
}

- (void)finishCurrentSectionLoad
{
    [self.loadingView removeFromSuperview];
    [self addSubview:self.tableView];
    self.tableView.frame = CGRectMake(0, kDramaHeaderViewHeight, self.width, self.height - kDramaHeaderViewHeight);
}

- (void)showErrorView
{
    [self.loadingView removeFromSuperview];
    [self addSubview:self.errorView];
    [self bringSubviewToFront:self.errorView];
}


#pragma mark - UIAction
- (IBAction)onClickRetry:(id)sender
{
    [self.errorView removeFromSuperview];
    [self addSubview:self.loadingView];
    [self bringSubviewToFront:self.loadingView];
    [self loadCurrentSection];
}

@end
