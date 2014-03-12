//
//  WonderMovieInfoView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-26.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "WonderMoviePlayerConstants.h"
#import "WonderMovieInfoView.h"
#import "UIView+Sizes.h"

#define kAutoNextToastWidth (180 * (27. / 40))
#define kAutoNextToastHeight 27

@interface WonderMovieInfoView ()
@property (nonatomic, strong) UILabel *volumeLabel;
@property (nonatomic, strong) UIImageView *volumeImageView;
@property (nonatomic, strong) UILabel *brightnessLabel;
@property (nonatomic, strong) UIView *toastView;
@property (nonatomic, strong) UILabel *toastLabel;
@property (nonatomic, strong) UIView *errorView;
@end

@implementation WonderMovieInfoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.clipsToBounds = YES;
        
        UIFont *font = [UIFont boldSystemFontOfSize:23];
        UILabel *progressTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 18+50-44, 100, 100)];
        self.progressTimeLabel = progressTimeLabel;
        self.progressTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.progressTimeLabel.textAlignment = UITextAlignmentLeft;
        self.progressTimeLabel.font = font;
        self.progressTimeLabel.backgroundColor = [UIColor clearColor];
        self.progressTimeLabel.textColor = [UIColor whiteColor];
        self.progressTimeLabel.height = font.lineHeight;
//        self.progressTimeLabel.hidden = YES;
        self.progressTimeLabel.layer.shadowOpacity = 0.5;
        self.progressTimeLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.progressTimeLabel.layer.shadowRadius = 1;
        self.progressTimeLabel.layer.shadowOffset = CGSizeMake(0, 1);
        [self addSubview:self.progressTimeLabel];
        
//        CGFloat centerButtonSize = 138 / 2;
        self.replayButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [self.replayButton setImage:QQVideoPlayerImage(@"replay") forState:UIControlStateNormal];
        [self.replayButton setImage:QQVideoPlayerImage(@"play") forState:UIControlStateNormal];
//        self.replayButton.size = CGSizeMake(centerButtonSize, centerButtonSize);
        self.replayButton.size = self.replayButton.currentImage.size;
        self.replayButton.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        self.replayButton.hidden = YES;
        self.replayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:self.replayButton];
        
        self.centerPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.centerPlayButton setImage:QQVideoPlayerImage(@"play") forState:UIControlStateNormal];
        self.centerPlayButton.size = self.centerPlayButton.currentImage.size;
        self.centerPlayButton.center = self.replayButton.center;
        self.centerPlayButton.hidden = YES;
        self.centerPlayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:self.centerPlayButton];

        UIView *toastView = [[UIView alloc] initWithFrame:CGRectMake(0, 10, kAutoNextToastWidth, kAutoNextToastHeight)];
        toastView.backgroundColor = [UIColor clearColor];
        toastView.alpha = 0;
        toastView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        toastView.center = CGPointMake(CGRectGetMidX(self.bounds), toastView.center.y);
        
        UIImageView *toastFrameImageView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"toast_frame")];
        toastFrameImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        toastFrameImageView.frame = toastView.bounds;
        toastFrameImageView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
        [toastView addSubview:toastFrameImageView];
        
        UILabel *toastLabel = [[UILabel alloc] initWithFrame:toastView.bounds];
        toastLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        toastLabel.textColor = [UIColor whiteColor];
        toastLabel.textAlignment = UITextAlignmentCenter;
        toastLabel.font = [UIFont systemFontOfSize:12];
        toastLabel.backgroundColor = [UIColor clearColor];
        [toastView addSubview:toastLabel];
        self.toastLabel = toastLabel;
        [self addSubview:toastView];
        self.toastView = toastView;
        
        UIView *errorView = [[UIView alloc] initWithFrame:self.bounds];
        errorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        errorView.backgroundColor = [UIColor clearColor];
        errorView.hidden = YES;
        UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.text = NSLocalizedString(@"播放地址失效，", nil);
        [label sizeToFit];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = self.bounds;
        [button setTitle:NSLocalizedString(@"源网页播放", nil) forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        self.openSourceButton = button;
        [button.titleLabel sizeToFit];
        button.bounds = button.titleLabel.bounds;
        CGFloat width = label.width + button.width;
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, label.height)];
        titleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        label.origin = CGPointZero;
        [titleView addSubview:label];
        button.origin = CGPointMake(label.right, 0);
        [titleView addSubview:button];
        [errorView addSubview:titleView];
        titleView.center = CGPointMake(CGRectGetMidX(errorView.bounds), CGRectGetMidY(errorView.bounds));

        self.errorView = errorView;
        [self addSubview:errorView];
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissToastView) object:nil];
}

#pragma mark Loading View

- (UIView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 181, 101 + 20)];
        _loadingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        UIImageView *loadingIndicator = [[UIImageView alloc] initWithImage:
//                                         QQActivityIndicatorImage(@"color_b")];
                                         QQVideoPlayerImage(@"loading")];
        self.loadingIndicator = loadingIndicator;
        self.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.loadingIndicator.contentMode = UIViewContentModeCenter;
        self.loadingIndicator.frame = CGRectMake(0, 0, _loadingView.width, _loadingView.height - 20);
        [_loadingView addSubview:self.loadingIndicator];

        UILabel *loadingPercentLabel = [[UILabel alloc] initWithFrame:self.loadingIndicator.frame];
        self.loadingPercentLabel = loadingPercentLabel;
        self.loadingPercentLabel.text = @"0%";
        self.loadingPercentLabel.textAlignment = UITextAlignmentCenter;
        self.loadingPercentLabel.backgroundColor = [UIColor clearColor];
        self.loadingPercentLabel.textColor = [UIColor whiteColor];
        
#ifndef MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
        self.loadingPercentLabel.hidden = YES;
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
        
        [_loadingView addSubview:self.loadingPercentLabel];
        
        CGFloat maxMessageWidth = self.width / 2 > _loadingView.width ? self.width / 2 : _loadingView.width;
        UILabel *loadingMessageLabel = [[UILabel alloc] initWithFrame:
                                        CGRectMake(- (maxMessageWidth - _loadingView.width)/2, self.loadingIndicator.bottom, maxMessageWidth, 20)];
                                        //CGRectMake(0, self.loadingIndicator.bottom, _loadingView.width , 20)];
        self.loadingMessageLabel = loadingMessageLabel;
        self.loadingMessageLabel.text = @"";// NSLocalizedString(@" 正在缓冲...", @"");
        self.loadingMessageLabel.textAlignment = UITextAlignmentCenter;
        self.loadingMessageLabel.backgroundColor = [UIColor clearColor];
        self.loadingMessageLabel.textColor = [UIColor whiteColor];
        self.loadingMessageLabel.font = [UIFont systemFontOfSize:12];
//        self.loadingMessageLabel.hidden = YES;
        [_loadingView addSubview:self.loadingMessageLabel];
        
        _loadingView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        _loadingView.hidden = YES;
        [self addSubview:_loadingView];
    }
    return _loadingView;
}

#pragma mark Public
- (void)startLoading
{
    //NSLog(@"startLoading %d, %d", self.loadingView.hidden, [self.loadingIndicator.layer.animationKeys containsObject:@"rotationAnimation"]);
	self.loadingView.hidden = NO;
    // Bugfix for iOS7
    // Animation will be missed if it is created before presentation in iOS7, so create animation on demand.
    static NSString *animationKey = @"rotationAnimation";
    if (![self.loadingIndicator.layer.animationKeys containsObject:animationKey]) {
        CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = @(M_PI / 180 * 360);
        rotationAnimation.duration = 1.0f;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = HUGE_VALF;
        rotationAnimation.removedOnCompletion = NO;
//        rotationAnimation.delegate = self;
        
        [self.loadingIndicator.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    }
}

- (void)stopLoading
{
    self.loadingView.hidden = YES;
}


- (void)showProgressTime:(BOOL)show animated:(BOOL)animated
{
    if (show) {
        self.progressTimeLabel.alpha = 1;
    }
    else {
        [self performSelector:@selector(dismissProgressTime) withObject:nil afterDelay:3];
    }
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissProgressTime) object:nil];
//    [self performSelector:@selector(dismissProgressTime) withObject:nil afterDelay:3];
}

- (void)dismissProgressTime
{
    [UIView animateWithDuration:1.f animations:^{
        self.progressTimeLabel.alpha = 0;
    }];
}

//- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
//{
//    NSLog(@"animationDidStop %@ %d", [(CABasicAnimation *)anim keyPath], flag);
//}

#pragma mark VolumeView & BrightnessView
- (UIView *)volumeView
{
#ifdef MTT_TWEAK_WONDER_MOVIE_HIDE_SYSTEM_VOLUME_VIEW
    if (_volumeView == nil) {
        CGFloat width = 120;
        CGFloat y = 20;
        _volumeView = [[UIView alloc] initWithFrame:CGRectMake((self.width - width) / 2, y, width, 55)];
        _volumeView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        _volumeView.layer.cornerRadius = 3;
        _volumeView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2].CGColor;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"volume") highlightedImage:QQVideoPlayerImage(@"mute")];
        self.volumeImageView = imageView;
        [_volumeView addSubview:imageView];
        imageView.origin = CGPointMake(14, (_volumeView.height - imageView.height) / 2);
        
        _volumeLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageView.right + 7, 0, _volumeView.width - imageView.right - 7, _volumeView.height)];
        _volumeLabel.backgroundColor = [UIColor clearColor];
        _volumeLabel.textAlignment = UITextAlignmentCenter;
        _volumeLabel.textColor = [UIColor whiteColor];
        _volumeLabel.font = [UIFont systemFontOfSize:18];
        [_volumeView addSubview:_volumeLabel];
        _volumeView.alpha = 0;
    }
    return _volumeView;
#else
    return nil;
#endif
}

- (UIView *)brightnessView
{
    if (_brightnessView == nil) {
        CGFloat width = 120;
        CGFloat y = 20;
        _brightnessView = [[UIView alloc] initWithFrame:CGRectMake((self.width - width) / 2, y, width, 55)];
        _brightnessView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        _brightnessView.layer.cornerRadius = 3;
        _brightnessView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2].CGColor;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"brightness")];
        [_brightnessView addSubview:imageView];
        imageView.origin = CGPointMake(14, (_brightnessView.height - imageView.height) / 2);
        
        _brightnessLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageView.right + 7, 0, _brightnessView.width - imageView.right - 7, _brightnessView.height)];
        _brightnessLabel.backgroundColor = [UIColor clearColor];
        _brightnessLabel.textAlignment = UITextAlignmentCenter;
        _brightnessLabel.textColor = [UIColor whiteColor];
        _brightnessLabel.font = [UIFont systemFontOfSize:18];
        [_brightnessView addSubview:_brightnessLabel];
        _brightnessView.alpha = 0;
    }
    return _brightnessView;
}


- (void)showVolume:(CGFloat)volume
{
    [self.brightnessView removeFromSuperview];
    [self addSubview:self.volumeView];
    self.volumeView.alpha = 1;
    self.brightnessView.alpha = 0;
    if (volume <= 0) {
        self.volumeImageView.highlighted = YES;
    }
    else {
        self.volumeImageView.highlighted = NO;
    }
    self.volumeLabel.text = [NSString stringWithFormat:@"%d%%", (int)(volume * 100)];
    [UIView animateWithDuration:0.5f delay:1.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.volumeView.alpha = 0;
    } completion:nil];
}

- (void)showBrightness:(CGFloat)brightness
{
    [self.volumeView removeFromSuperview];
    [self addSubview:self.brightnessView];
    self.volumeView.alpha = 0;
    self.brightnessView.alpha = 1;
    self.brightnessLabel.text = [NSString stringWithFormat:@"%d%%", (int)(brightness * 100)];
    [UIView animateWithDuration:0.5f delay:1.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.brightnessView.alpha = 0;
    } completion:nil];
}

- (void)showAutoNextToast:(BOOL)show animated:(BOOL)animated
{
    [self.toastView removeFromSuperview];
    [self addSubview:self.toastView];
    self.toastView.center = CGPointMake(CGRectGetMidX(self.bounds), self.toastView.center.y);
    self.toastLabel.text = NSLocalizedString(@"即将自动播放下一集", nil);
    self.toastView.size = CGSizeMake(kAutoNextToastWidth, kAutoNextToastHeight);
    
    [self showToast:show animated:animated];
}

- (void)showDownloadToast:(NSString *)toast show:(BOOL)show animated:(BOOL)animated
{
    [self.toastView removeFromSuperview];
    [self addSubview:self.toastView];
    self.toastLabel.text = toast;
//    [self fitDownloadToastFrame];
    [self fitCenterToastFrame];
    
    [self showToast:show animated:animated];
}

- (void)showCommonToast:(NSString *)toast show:(BOOL)show animated:(BOOL)animated
{
    [self.toastView removeFromSuperview];
    [self addSubview:self.toastView];
    self.toastLabel.text = toast;
    [self fitCenterToastFrame];
    
    [self showToast:show animated:animated];
}

- (void)updateDownloadToast:(NSString *)toast
{
    self.toastLabel.text = toast;
//    [self fitDownloadToastFrame];
    [self fitCenterToastFrame];
}

- (void)fitDownloadToastFrame
{
    self.toastView.size = CGSizeMake(kAutoNextToastWidth, kAutoNextToastHeight);
    [self.toastLabel sizeToFit];
    CGRect rect = self.toastLabel.frame;
    rect.size.width += 20;
    rect.size.height = kAutoNextToastHeight;
    rect.origin.y = 10;
    rect.origin.x = self.width - 10 - rect.size.width;
    self.toastView.frame = rect;
    self.toastLabel.frame = self.toastView.bounds;
}

- (void)fitCenterToastFrame
{
    self.toastView.size = CGSizeMake(180, 40);
    [self.toastLabel sizeToFit];
    CGRect rect = self.toastLabel.frame;
    rect.size.width += 20;
    rect.size.height = 40;
    rect.origin.y = 10;
    rect.origin.x = (self.width - rect.size.width) / 2;
    self.toastView.frame = rect;
    self.toastLabel.frame = self.toastView.bounds;
}

- (void)showToast:(BOOL)show animated:(BOOL)animated
{
    [UIView animateWithDuration:(animated ? 0.5f : 0) animations:^{
        self.toastView.alpha = show ? 1 : 0;
    } completion:^(BOOL finished) {
        if (show) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissToastView) object:nil];
            [self performSelector:@selector(dismissToastView) withObject:nil afterDelay:5];
        }
    }];
}

- (void)dismissToastView
{
    [UIView animateWithDuration:0.5f animations:^{
        self.toastView.alpha = 0;
    }];
}

- (void)showError:(BOOL)show
{
    self.errorView.hidden = !show;
}

@end
