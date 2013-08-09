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
@property (nonatomic, retain) UIProgressView *progressView;
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
    self.progressView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.progressView.frame = self.bounds;
    [self addSubview:self.progressView];
    self.progressView.center = CGPointMake(self.progressView.center.x, self.center.y);
    
    self.progressIndicator = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)] autorelease];
    self.progressIndicator.backgroundColor = [UIColor redColor];
    [self addSubview:self.progressIndicator];
    
    [self addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)] autorelease]];
    
    [self setProgress:0];
}

#pragma mark Progress action
- (void)setProgress:(CGFloat)progress
{
//    NSLog(@"setProgrss: %f, %f", progress, self.progressView.progress);
    if (fabs(progress - self.progressView.progress) > 0.01) {
        [self.progressView setProgress:progress];
        self.progressIndicator.center = CGPointMake(self.progressView.left + self.progressView.width * progress, self.progressView.center.y);
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
