//
//  WonderProgressView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_MOVIE_PLAYER
#import "WonderMoviePlayerConstants.h"
#import "WonderProgressView.h"
#import "UIView+Sizes.h"

@interface WonderProgressView ()
@property (nonatomic, strong) UIImageView *progressBottomView;
@property (nonatomic, strong) UIImageView *progressCacheView;
@property (nonatomic, strong) UIImageView *progressTopView;
@property (nonatomic, strong) UIButton *progressIndicator;
@end

@implementation WonderProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _enabled = YES;
        [self setupView];
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    
}

- (void)setupView
{
    UIImageView *progressBottomView = [[UIImageView alloc] init];
    self.progressBottomView = progressBottomView;
//    self.progressBottomView.backgroundColor = [UIColor blueColor];
    self.progressBottomView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
    self.progressBottomView.image = QQVideoPlayerImage(@"progressbar_bottom");
    [self addSubview:self.progressBottomView];
    
    UIImageView *progressCacheView = [[UIImageView alloc] init];
    self.progressCacheView = progressCacheView;
//    self.progressCacheView.backgroundColor = [UIColor redColor];
    self.progressCacheView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
    self.progressCacheView.image = QQVideoPlayerImage(@"progressbar_cache");
    [self addSubview:self.progressCacheView];
    
    UIImageView *progressTopView = [[UIImageView alloc] init];
    self.progressTopView = progressTopView;
//    self.progressTopView.backgroundColor = [UIColor whiteColor];
    self.progressTopView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
    self.progressTopView.image = QQVideoPlayerImage(@"progressbar_top");
    self.progressTopView.clipsToBounds = YES;
    [self addSubview:self.progressTopView];
    
    self.progressIndicator = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.progressIndicator setImage:QQVideoPlayerImage(@"progressbar_indicator_normal") forState:UIControlStateNormal];
//    [self.progressIndicator setImage:QQVideoPlayerImage(@"progressbar_indicator_press") forState:UIControlStateHighlighted];
//    [self.progressIndicator setImage:QQVideoPlayerImage(@"progressbar_indicator_press") forState:UIControlStateSelected];
//    self.progressIndicator.size = CGSizeMake(39, 39);
    self.progressIndicator.size = CGSizeMake(39 + 10, 39 + 10);
//    self.progressIndicator.backgroundColor = [UIColor lightTextColor];
    [self addSubview:self.progressIndicator];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)]];
    
    [self setProgress:0];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat progressHeight = 2;
    /*
     * NOTE: the inner progress view width should not be the same as self.width,
     * otherwise the progressIndicator will be hard to pressed since half of it is outside the superview
     */
    CGFloat width = self.width;
    CGFloat progressIndicatorVisualWidth = 20;
    self.progressBottomView.frame = CGRectMake(0, (self.height - progressHeight) / 2 + kProgressIndicatorLeading, width, progressHeight);
    self.progressCacheView.frame = self.progressBottomView.frame;
    self.progressCacheView.width = self.progressBottomView.width * self.cacheProgress;
    self.progressTopView.frame = self.progressCacheView.frame;
    self.progressTopView.width = self.progressBottomView.width * self.progress;
    self.progressIndicator.center = CGPointMake(progressIndicatorVisualWidth / 2 + self.progressBottomView.left + (self.progressBottomView.width - progressIndicatorVisualWidth) * self.progress, self.center.y);
    
//    // ugly tuning
//    if (self.progressTopView.width < self.progressTopView.image.size.width) {
//        self.progressTopView.contentMode = UIViewContentModeLeft;
//    }
//    else {
//        self.progressTopView.contentMode = UIViewContentModeScaleToFill;
//    }
}

#pragma mark State
- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    self.progressIndicator.enabled = enabled;
}

#pragma mark Progress action
- (void)setProgress:(CGFloat)progress
{
//    NSLog(@"setProgress %f, %f, %f", progress, self.progressTopView.width, self.progressCacheView.width);
    if (_progress != progress) {
        _progress = progress;
        [self setNeedsLayout];
    }
}

- (void)setCacheProgress:(CGFloat)cacheProgress
{
//    NSLog(@"setCacheProgress %f", cacheProgress);
    if (_cacheProgress != cacheProgress) {
        _cacheProgress = cacheProgress;
        [self setNeedsLayout];
    }
}

- (void)notifyProgressChanged:(CGFloat)progress
{
    if ([self.delegate respondsToSelector:@selector(wonderMovieProgressView:didChangeProgress:)]) {
        [self.delegate wonderMovieProgressView:self didChangeProgress:progress];
    }
}

- (void)notifyProgressBegin
{
    self.progressIndicator.selected = YES;
    if ([self.delegate respondsToSelector:@selector(wonderMovieProgressViewBeginChangeProgress:)]) {
        [self.delegate wonderMovieProgressViewBeginChangeProgress:self];
    }
}

- (void)notifyProgressEnd
{
    self.progressIndicator.selected = NO;
    if ([self.delegate respondsToSelector:@selector(wonderMovieProgressViewEndChangeProgress:)]) {
        [self.delegate wonderMovieProgressViewEndChangeProgress:self];
    }
}

#pragma mark UI Interaction
- (void)onTap:(UITapGestureRecognizer *)gr
{
    CGPoint pt = [gr locationInView:self];
    CGFloat progress = self.width == 0 ? 1 : pt.x / self.width;
//    NSLog(@"onTap: %f", progress);
    [self setProgress:progress];
    
    [self notifyProgressBegin];
    [self notifyProgressChanged:progress];
    [self notifyProgressEnd];
}

- (void)onPan:(UIPanGestureRecognizer *)gr
{
    CGPoint pt = [gr locationInView:self.progressIndicator.superview];
    CGPoint offset = [gr translationInView:self.progressIndicator.superview];
    
    CGFloat progress = self.width == 0 ? 1 : (pt.x + offset.x) / self.width;
    progress = MIN(1, MAX(0, progress));
//    NSLog(@"onPan %d %f, %f", gr.state, offset.x, progress);
    [self setProgress:progress];
//    view.center = CGPointMake(view.center.x + offset.x, view.center.y);
    
    [gr setTranslation:CGPointZero inView:self];
    
    if (gr.state == UIGestureRecognizerStateBegan) {
        [self notifyProgressBegin];
        [self notifyProgressChanged:progress];
    }
    else if (gr.state == UIGestureRecognizerStateEnded) {
        [self notifyProgressChanged:progress];
        [self notifyProgressEnd];
    }
    else if (gr.state == UIGestureRecognizerStateChanged) {
        [self notifyProgressChanged:progress];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end

#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER
