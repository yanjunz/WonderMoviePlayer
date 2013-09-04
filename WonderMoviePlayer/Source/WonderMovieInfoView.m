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

@implementation WonderMovieInfoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIFont *font = [UIFont boldSystemFontOfSize:23];
        self.progressTimeLabel = [[[UILabel alloc] initWithFrame:CGRectMake(17, 18+50, 100, 100)] autorelease];
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
        
        
    }
    return self;
}

- (void)dealloc
{
    self.progressTimeLabel = nil;
    
    self.loadingView = nil;
    self.loadingIndicator = nil;
    self.loadingMessageLabel = nil;
    self.loadingPercentLabel = nil;
    [super dealloc];
}

#pragma mark Loading View

- (UIView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 81, 101)];
        _loadingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        self.loadingIndicator = [[[UIImageView alloc] initWithImage:QQImage(@"videoplayer_loading")] autorelease];
        self.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [_loadingView addSubview:self.loadingIndicator];
        
        self.loadingPercentLabel = [[[UILabel alloc] initWithFrame:self.loadingIndicator.frame] autorelease];
        self.loadingPercentLabel.text = @"0%";
        self.loadingPercentLabel.textAlignment = UITextAlignmentCenter;
        self.loadingPercentLabel.backgroundColor = [UIColor clearColor];
        self.loadingPercentLabel.textColor = [UIColor whiteColor];
        [_loadingView addSubview:self.loadingPercentLabel];
        
        self.loadingMessageLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, self.loadingIndicator.bottom, _loadingView.width, 20)] autorelease];
        self.loadingMessageLabel.text = @"Loading...";
        self.loadingMessageLabel.textAlignment = UITextAlignmentCenter;
        self.loadingMessageLabel.backgroundColor = [UIColor clearColor];
        self.loadingMessageLabel.textColor = [UIColor whiteColor];
        [_loadingView addSubview:self.loadingMessageLabel];
    }
    return _loadingView;
}

#pragma mark Public
- (void)startLoading
{
    if (self.loadingView.superview != self) {
        [self.loadingView removeFromSuperview];
        [self addSubview:self.loadingView];
        _loadingView.center = self.center;
    }
    
	CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI / 180 * 360);
    rotationAnimation.duration = 1.0f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [self.loadingIndicator.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)stopLoading
{
    [self.loadingView removeFromSuperview];
}


- (void)showProgressTime:(BOOL)show animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? 0.4f : 0 animations:^{
        self.progressTimeLabel.alpha = show ? 1 : 0;
    }];
}

@end
