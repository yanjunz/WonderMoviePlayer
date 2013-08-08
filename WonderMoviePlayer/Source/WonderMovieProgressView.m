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
}

#pragma mark Progress action
- (void)setProgress:(CGFloat)progress
{
    [self.progressView setProgress:progress];
}

@end
