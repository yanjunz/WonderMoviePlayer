//
//  DramaTableView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/28/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "DramaTableView.h"
#import "UIView+Sizes.h"

@implementation DramaTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    if (self = [super initWithFrame:frame style:style]) {
        UIView *loadingHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 35)];
        loadingHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.loadingHeaderView = loadingHeaderView;
//        loadingHeaderView.clipsToBounds = YES;
        [loadingHeaderView release];
        
        UIActivityIndicatorView *loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [loadingHeaderView addSubview:loadingIndicator];
        loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        loadingIndicator.hidesWhenStopped = YES;
        loadingIndicator.center = CGPointMake(CGRectGetMidX(loadingHeaderView.bounds) - 40, CGRectGetMidY(loadingHeaderView.bounds));
        [loadingHeaderView addSubview:loadingIndicator];
        [loadingIndicator release];
        _headerLoadingView = loadingIndicator;
        
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:loadingHeaderView.bounds];
        loadingLabel.text = NSLocalizedString(@"正在加载", nil);
        loadingLabel.font = [UIFont systemFontOfSize:13];
        loadingLabel.textColor = [UIColor whiteColor];
        loadingLabel.textAlignment = UITextAlignmentCenter;
        loadingLabel.backgroundColor = [UIColor clearColor];
        loadingLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [loadingHeaderView addSubview:loadingLabel];
        [loadingLabel release];

        UIView *retryHeaderView = [[UIView alloc] initWithFrame:loadingHeaderView.frame];
        retryHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.retryHeaderView = retryHeaderView;
        [retryHeaderView release];
        
        UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [retryButton setTitle:NSLocalizedString(@"加载失败，点击重试", nil) forState:UIControlStateNormal];
        retryButton.frame = retryHeaderView.bounds;
        [retryButton addTarget:self action:@selector(onClickRetryHeader:) forControlEvents:UIControlEventTouchUpInside];
        retryButton.backgroundColor = [UIColor clearColor];
        [retryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        retryButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [retryHeaderView addSubview:retryButton];
    }
    return self;
}

- (void)dealloc
{
    self.loadingHeaderView = nil;
    self.retryHeaderView = nil;
    
    [super dealloc];
}

#pragma mark State
- (void)setHeaderState:(DramaLoadMoreState)state
{
    NSLog(@"setHeaderState %d", state);
    _headerState = state;
    switch (state) {
        case DramaLoadMoreStateNormal:
            [self setTableHeaderViewAnimated:nil];
            break;
        case DramaLoadMoreStateLoading:
            [self setTableHeaderViewAnimated:self.loadingHeaderView];
            [_headerLoadingView startAnimating];
            break;
        case DramaLoadMoreStateFailed:
            [self setTableHeaderViewAnimated:self.retryHeaderView];
            break;
    }

    [self setNeedsLayout];
}

- (void)setTableHeaderViewAnimated:(UIView *)tableHeaderView
{
//    NSLog(@"setTableHeaderViewAnimated %@, %@", tableHeaderView, self.tableHeaderView);
    if (tableHeaderView == nil) {
        if (self.tableHeaderView != nil) {
            CGFloat orgHeight = self.tableHeaderView.height;
            [UIView animateWithDuration:0.3f animations:^{
                self.tableHeaderView.height = 0;
            } completion:^(BOOL finished) {
                self.tableHeaderView.height = orgHeight;
//                NSLog(@"[2]%@", self.tableHeaderView);
                self.tableHeaderView = nil;
            }];
        }
    }
    else {
        CGFloat initHeight = 0;
        if (self.tableHeaderView != nil) {
            initHeight = self.tableHeaderView.height;
        }
        CGFloat destHeight = tableHeaderView.height;
        
        tableHeaderView.height = initHeight;
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            tableHeaderView.height = destHeight;
            self.tableHeaderView = tableHeaderView;
        } completion:^(BOOL finished) {
//            NSLog(@"[1]%@", self.tableHeaderView);
        }];
    }
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    NSLog(@"scrollViewDidScroll %f", scrollView.contentOffset.y);
    if (_headerLoadingEnabled) {
        BOOL loadMore = [self shouldTriggerHeaderLoadMore:scrollView];
        if (scrollView.isDragging && _headerState == DramaLoadMoreStateNormal && loadMore && !_isHeaderLoading) {
            [self setHeaderState:DramaLoadMoreStateLoading];
            [self loadMoreHeader];
        }
    }
}

- (BOOL)shouldTriggerHeaderLoadMore:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.y;
    if (offset <= 0) {
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark Public
- (void)failHeaderLoadMore
{
    if (_headerLoadingEnabled) {
        if (_headerState == DramaLoadMoreStateLoading) {
            [self setHeaderState:DramaLoadMoreStateFailed];
        }
    }
}

- (void)finishHeaderLoadMore
{
    if (_headerLoadingEnabled) {
        if (_headerState == DramaLoadMoreStateLoading) {
            [self setHeaderState:DramaLoadMoreStateNormal];
        }
    }
}

#pragma mark UI Action
- (IBAction)onClickRetryHeader:(id)sender
{
    [self setHeaderState:DramaLoadMoreStateLoading];
    [self loadMoreHeader];
}

- (void)loadMoreHeader
{
    if ([self.delegate respondsToSelector:@selector(dramaTableViewDidTriggerLoadMoreHeader:)]) {
        [self.delegate dramaTableViewDidTriggerLoadMoreHeader:self];
    }
}

@end
