//
//  WonderMovieProgressView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "WonderMovieProgressView.h"
#import "UIView+Sizes.h"

@interface WonderMovieProgressView ()
//@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIImageView *progressBottomView;
@property (nonatomic, retain) UIImageView *progressCacheView;
@property (nonatomic, retain) UIImageView *progressTopView;
@property (nonatomic, retain) UIButton *progressIndicator;
@end

@implementation WonderMovieProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    self.progressBottomView = [[[UIImageView alloc] init] autorelease];
//    self.progressBottomView.backgroundColor = [UIColor blueColor];
    self.progressBottomView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
    self.progressBottomView.image = QQImage(@"videoplayer_progressbar_bottom");
    [self addSubview:self.progressBottomView];
    
    self.progressCacheView = [[[UIImageView alloc] init] autorelease];
//    self.progressCacheView.backgroundColor = [UIColor redColor];
    self.progressCacheView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
    self.progressCacheView.image = QQImage(@"videoplayer_progressbar_cache");
    [self addSubview:self.progressCacheView];
    
    self.progressTopView = [[[UIImageView alloc] init] autorelease];
//    self.progressTopView.backgroundColor = [UIColor whiteColor];
    self.progressTopView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
    self.progressTopView.image = QQImage(@"videoplayer_progressbar_top");
    [self addSubview:self.progressTopView];
    
//    self.progressIndicator = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)] autorelease];
    self.progressIndicator = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.progressIndicator setImage:QQImage(@"videoplayer_progressbar_indicator_normal") forState:UIControlStateNormal];
    [self.progressIndicator setImage:QQImage(@"videoplayer_progressbar_indicator_press") forState:UIControlStateHighlighted];
    self.progressIndicator.size = CGSizeMake(39, 39);
//    self.progressIndicator.backgroundColor = [UIColor lightTextColor];
    [self addSubview:self.progressIndicator];
    
    [self.progressIndicator addGestureRecognizer:[[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)] autorelease]];
    [self addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)] autorelease]];
    
    [self setProgress:0];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat progressHeight = 6;
    self.progressBottomView.frame = CGRectMake(0, (self.height - progressHeight) / 2, self.width, progressHeight);
    self.progressCacheView.frame = self.progressBottomView.frame;
    self.progressCacheView.width = self.progressBottomView.width * self.cacheProgress;
    self.progressTopView.frame = self.progressCacheView.frame;
    self.progressTopView.width = self.progressBottomView.width * self.progress;
    self.progressIndicator.center = CGPointMake(self.progressBottomView.left + self.progressBottomView.width * self.progress, self.progressBottomView.center.y);
}

#pragma mark Progress action
- (void)setProgress:(CGFloat)progress
{
    NSLog(@"setProgress %f, %f, %f", progress, self.progressTopView.width, self.progressCacheView.width);
    if (self.progressTopView.width > 215) {
        NSLog(@"setProgress NaN %f", progress);
    }
    if (_progress != progress) {
        _progress = progress;
        [self setNeedsLayout];
    }
}

- (void)setCacheProgress:(CGFloat)cacheProgress
{
    NSLog(@"setCacheProgress %f", cacheProgress);
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
    if ([self.delegate respondsToSelector:@selector(wonderMovieProgressViewBeginChangeProgress:)]) {
        [self.delegate wonderMovieProgressViewBeginChangeProgress:self];
    }
}

- (void)notifyProgressEnd
{
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
    UIView *view = gr.view;
    CGPoint pt = [gr locationInView:view.superview];
    CGPoint offset = [gr translationInView:view.superview];
//    NSLog(@"onPan %d %f", gr.state, offset.x);
    CGFloat progress = self.width == 0 ? 1 : (pt.x + offset.x) / self.width;
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

@end
