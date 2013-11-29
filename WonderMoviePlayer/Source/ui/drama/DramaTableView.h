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
    
    DramaLoadMoreState _headerState;
    DramaLoadMoreState _footerState;
}

@property (nonatomic, assign) id<DramaTableViewDelegate> delegate;
// Header View
@property (nonatomic, retain) UIView *loadingHeaderView;
@property (nonatomic, retain) UIView *retryHeaderView;

// Footer View
@property (nonatomic, retain) UIView *dramaFooterView;

@property (nonatomic, assign) BOOL headerLoadingEnabled;
@property (nonatomic, assign) BOOL footerLoadingEnabled;

@property (nonatomic, assign) BOOL isHeaderLoading;
@property (nonatomic, assign) BOOL isFooterLoading;

- (void)failHeaderLoadMore;
- (void)finishHeaderLoadMore;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
@end
