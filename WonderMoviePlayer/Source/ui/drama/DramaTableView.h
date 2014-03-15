//
//  DramaTableView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/28/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DramaLoadMoreStateNormal,
    DramaLoadMoreStateLoading,
    DramaLoadMoreStateFailed,
} DramaLoadMoreState;

@class DramaTableView;

@protocol DramaTableViewDelegate <UITableViewDelegate>
@optional
- (void)dramaTableViewDidTriggerLoadMoreHeader:(DramaTableView *)tableView;
- (void)dramaTableViewDidTriggerLoadMoreFooter:(DramaTableView *)tableView;

@end

@interface DramaTableView : UITableView <UIScrollViewDelegate>
{
    UIActivityIndicatorView *_headerLoadingView;
    UIActivityIndicatorView *_footerLoadingView;
    
    DramaLoadMoreState _headerState;
    DramaLoadMoreState _footerState;
}

@property (nonatomic, weak) id<DramaTableViewDelegate> delegate;
// Header View
@property (nonatomic, strong) UIView *loadingHeaderView;
@property (nonatomic, strong) UIView *retryHeaderView;

// Footer View
@property (nonatomic, strong) UIView *loadingFooterView;
@property (nonatomic, strong) UIView *retryFooterView;

@property (nonatomic, assign) BOOL headerLoadingEnabled;
@property (nonatomic, assign) BOOL footerLoadingEnabled;

@property (nonatomic, assign) BOOL isHeaderLoading;
@property (nonatomic, assign) BOOL isFooterLoading;

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style indicatorStyle:(UIActivityIndicatorViewStyle)indicatorStyle loadingTextColor:(UIColor *)loadingTextColor errorTextColor:(UIColor *)errorTextColor;
- (void)failLoadMoreHeader;
- (void)finishLoadMoreHeader;
- (void)failLoadMoreFooter;
- (void)finishLoadMoreFooter;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
@end
