//
//  WonderInfoView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-26.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"

@interface WonderInfoView : UIView
// Only show when setting progress
@property (nonatomic, strong) UILabel *progressTimeLabel;

// buffering
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIImageView *loadingIndicator;
@property (nonatomic, strong) UILabel *loadingPercentLabel;
@property (nonatomic, strong) UILabel *loadingMessageLabel;

// center button
@property (nonatomic, strong) UIButton *replayButton;
@property (nonatomic, strong) UIButton *centerPlayButton;

@property (nonatomic, strong) UIView *volumeView;
@property (nonatomic, strong) UIView *brightnessView;

@property (nonatomic, strong) UIButton *openSourceButton;

@property (nonatomic, strong) TTTAttributedLabel *toastLabel;

- (void)showProgressTime:(BOOL)show animated:(BOOL)animated;
- (void)startLoading;
- (void)stopLoading;

- (void)showVolume:(CGFloat)volume;
- (void)showBrightness:(CGFloat)brightness;

- (void)showAutoNextToast:(BOOL)show animated:(BOOL)animated;
- (void)showDownloadToast:(NSString *)toast show:(BOOL)show animated:(BOOL)animated;
- (void)showCommonToast:(NSString *)toast show:(BOOL)show animated:(BOOL)animated;
- (void)updateDownloadToast:(NSString *)toast;
- (void)showError:(BOOL)show;
@end
