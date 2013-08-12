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
@property (nonatomic, retain) UIImageView *progressIndicator;
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
    self.progressBottomView.backgroundColor = [UIColor blueColor];
    [self addSubview:self.progressBottomView];
    
    self.progressCacheView = [[[UIImageView alloc] init] autorelease];
    self.progressCacheView.backgroundColor = [UIColor redColor];
    [self addSubview:self.progressCacheView];
    
    self.progressTopView = [[[UIImageView alloc] init] autorelease];
    self.progressTopView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.progressTopView];
    
    self.progressIndicator = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)] autorelease];
    self.progressIndicator.backgroundColor = [UIColor lightTextColor];
    [self addSubview:self.progressIndicator];
    
    [self addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)] autorelease]];
    
    [self setProgress:0];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat progressHeight = 12;
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

#pragma mark UI Interaction
- (void)onTap:(UITapGestureRecognizer *)gr
{
    CGPoint pt = [gr locationInView:self];
    CGFloat progress = pt.x / self.width;
    NSLog(@"onTap: %f", progress);
    [self setProgress:progress];
    [self notifyProgressChanged:progress];
}

@end
