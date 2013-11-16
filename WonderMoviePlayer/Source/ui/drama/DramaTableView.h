//
//  DramaTableView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/16/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DramaTableLoadingStatePullOrPush,
    DramaTableLoadingViewNormal,
    DramaTableLoadingViewLoading,
} DramaTableLoadingState;

@interface DramaTableLoadingView : UIView {
    BOOL _forHeader;
    DramaTableLoadingState _state;
}

- (id)initForHeader:(BOOL)forHeader;
@end

@interface DramaTableView : UITableView
@property (nonatomic, retain) UIView *headerView;
@property (nonatomic, retain) UIView *footerView;
@end
