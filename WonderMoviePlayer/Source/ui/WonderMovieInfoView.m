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
        self.progressTimeLabel = [[[UILabel alloc] initWithFrame:CGRectMake(15, 18+50, 100, 100)] autorelease];
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
        
        CGFloat centerButtonSize = 138 / 2;
        self.replayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.replayButton setImage:QQImage(@"videoplayer_replay") forState:UIControlStateNormal];
        self.replayButton.size = CGSizeMake(centerButtonSize, centerButtonSize);
        self.replayButton.center = self.center;
        self.replayButton.hidden = YES;
        self.replayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:self.replayButton];
        
        self.centerPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.centerPlayButton setImage:QQImage(@"videoplayer_play") forState:UIControlStateNormal];
        self.centerPlayButton.frame = self.replayButton.frame;
        self.centerPlayButton.hidden = YES;
        self.centerPlayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self addSubview:self.centerPlayButton];
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
    
    self.replayButton = nil;
    self.centerPlayButton = nil;
    [super dealloc];
}

#pragma mark Loading View

- (UIView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 181, 101)];
        _loadingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        self.loadingIndicator = [[[UIImageView alloc] initWithImage:QQImage(@"videoplayer_loading")] autorelease];
        self.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.loadingIndicator.contentMode = UIViewContentModeCenter;
        self.loadingIndicator.frame = _loadingView.bounds;
        [_loadingView addSubview:self.loadingIndicator];
        [self addSubview:_loadingView];
        _loadingView.center = self.center;
        _loadingView.hidden = YES;
        
        self.loadingPercentLabel = [[[UILabel alloc] initWithFrame:self.loadingIndicator.frame] autorelease];
        self.loadingPercentLabel.text = @"0%";
        self.loadingPercentLabel.textAlignment = UITextAlignmentCenter;
        self.loadingPercentLabel.backgroundColor = [UIColor clearColor];
        self.loadingPercentLabel.textColor = [UIColor whiteColor];
        
#ifndef MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
        self.loadingPercentLabel.hidden = YES;
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
        
        [_loadingView addSubview:self.loadingPercentLabel];
        
        self.loadingMessageLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, self.loadingIndicator.bottom, _loadingView.width, 20)] autorelease];
        self.loadingMessageLabel.text = NSLocalizedString(@" 正在缓冲...", @"");
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
    [UIView animateWithDuration:animated ? 0.4f : 0 animations:^{
        self.progressTimeLabel.alpha = show ? 1 : 0;
    }];
}

//- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
//{
//    NSLog(@"animationDidStop %@ %d", [(CABasicAnimation *)anim keyPath], flag);
//}
@end
