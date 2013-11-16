//
//  DramaTableView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/16/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "DramaTableView.h"
#import "UIView+Sizes.h"

#define kLoadingViewHeight 33


@implementation DramaTableLoadingView

- (id)initForHeader:(BOOL)forHeader
{
    if (self = [super initWithFrame:CGRectZero]) {
        _forHeader = forHeader;
    }
    return self;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.isDragging) {
        
    }
}

@end


@implementation DramaTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    if (self = [super initWithFrame:frame style:style]) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, -kLoadingViewHeight, self.width, kLoadingViewHeight)];
    _headerView = headerView;
    headerView.backgroundColor = [UIColor redColor];
    UIActivityIndicatorView *headerIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [headerView addSubview:headerIndicatorView];
    [headerIndicatorView startAnimating];
    headerIndicatorView.center = CGPointMake(CGRectGetMidX(headerView.bounds), CGRectGetMidY(headerView.bounds));
    [headerIndicatorView release];
    [self addSubview:_headerView];
}



@end
