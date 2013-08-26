//
//  WonderMovieInfoView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-26.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WonderMovieInfoView : UIView
// Only show when setting progress
@property (nonatomic, retain) UILabel *progressTimeLabel;

// buffering
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) UIImageView *loadingIndicator;
@property (nonatomic, retain) UILabel *loadingPercentLabel;
@property (nonatomic, retain) UILabel *loadingMessageLabel;


- (void)showProgressTime:(BOOL)show animated:(BOOL)animated;
- (void)startLoading;
- (void)stopLoading;
@end
