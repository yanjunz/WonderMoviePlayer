//
//  WonderMovieFullscreenControlView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "WonderMovieFullscreenControlView.h"
#import "WonderMovieProgressView.h"
#import "UIView+Sizes.h"

@interface WonderMovieFullscreenControlView ()
@property (nonatomic, retain) WonderMovieProgressView *progressView;
@property (nonatomic, retain) UIView *bottomBar;
@property (nonatomic, retain) UIView *headerBar;
@property (nonatomic, retain) UIButton *actionButton;
@property (nonatomic, retain) UILabel *startLabel;
@property (nonatomic, retain) UILabel *durationLabel;
@end

@implementation WonderMovieFullscreenControlView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    self.backgroundColor = [UIColor clearColor];
    
    CGFloat bottomBarHeight = 40;
    CGFloat headerBarHeight = 40;
    CGFloat progressBarLeftPadding = 80;
    CGFloat progressBarRightPadding = 30;
    
    // setup bottomBar
    self.bottomBar = [[[UIView alloc] initWithFrame:CGRectMake(0, self.height - bottomBarHeight, self.width, bottomBarHeight)] autorelease];
    self.bottomBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.bottomBar];
    self.progressView = [[[WonderMovieProgressView alloc] initWithFrame:CGRectMake(progressBarLeftPadding, 0, self.bottomBar.width - progressBarLeftPadding - progressBarRightPadding, bottomBarHeight)] autorelease];
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.bottomBar addSubview:self.progressView];
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:10];
    self.actionButton.frame = CGRectMake(0, 0, 40, bottomBarHeight);
    [self.actionButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(onClickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.actionButton];
    
    self.startLabel = [[[UILabel alloc] initWithFrame:CGRectMake(self.actionButton.right + 5, 0, progressBarLeftPadding - self.actionButton.right - 5, bottomBarHeight)] autorelease];
    self.startLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    [self.bottomBar addSubview:self.startLabel];
    
    self.durationLabel = [[[UILabel alloc] initWithFrame:CGRectMake(self.progressView.right + 5, 0, self.width - self.progressView.right - 5, bottomBarHeight)] autorelease];
    self.durationLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    [self.bottomBar addSubview:self.durationLabel];
    
    
}

- (void)dealloc
{
    self.progressView = nil;
    self.bottomBar = nil;
    self.headerBar = nil;

    self.delegate = nil;
    [super dealloc];
}

#pragma mark MovieControlSource
- (void)play
{
    self.controlState = WonderMovieControlStatePlaying;
    if ([self.delegate respondsToSelector:@selector(movieControlSourcePlay:)]) {
        [self.delegate movieControlSourcePlay:self];
    }
}

- (void)pause
{
    self.controlState = WonderMovieControlStatePaused;
    if ([self.delegate respondsToSelector:@selector(movieControlSourcePause:)]) {
        [self.delegate movieControlSourcePause:self];
    }
}

- (void)resume
{
    self.controlState = WonderMovieControlStatePlaying;
    if ([self.delegate respondsToSelector:@selector(movieControlSourceResume:)]) {
        [self.delegate movieControlSourceResume:self];
    }
}

- (void)replay
{
    self.controlState = WonderMovieControlStatePlaying;
    if ([self.delegate respondsToSelector:@selector(movieControlSourceReplay:)]) {
        [self.delegate movieControlSourceReplay:self];
    }
}

- (void)setProgress:(CGFloat)progress
{
    self.controlState = WonderMovieControlStatePlaying;
//    [self.progressView setProgress:progress];
    if ([self.delegate respondsToSelector:@selector(movieControlSource:setProgress:)]) {
        [self.delegate movieControlSource:self setProgress:progress];
    }
}

- (void)exit
{
    self.controlState = WonderMovieControlStateEnded;
    if ([self.delegate respondsToSelector:@selector(movieControlSourceExit:)]) {
        [self.delegate movieControlSourceExit:self];
    }
}

#pragma mark UI Interaction
- (IBAction)onClickAction:(UIButton *)sender
{
    if (self.controlState == WonderMovieControlStateDefault) {
        [self play];
    }
    else if (self.controlState == WonderMovieControlStatePlaying) {
        [self pause];
    }
    else if (self.controlState == WonderMovieControlStatePaused) {
        [self resume];
    }
    else if (self.controlState == WonderMovieControlStateEnded) {
        [self replay];
    }
    
    NSArray *titles = @[@"default", @"playing", @"paused", @"ended"];
    [sender setTitle:titles[self.controlState] forState:UIControlStateNormal];
}

@end
