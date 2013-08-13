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

@interface WonderMovieFullscreenControlView () {
    NSTimeInterval _totalDuration;
    BOOL _bufferFromPaused;
}

@property (nonatomic, retain) WonderMovieProgressView *progressView;

// bottom bar
@property (nonatomic, retain) UIView *bottomBar;
@property (nonatomic, retain) UIButton *actionButton;
@property (nonatomic, retain) UILabel *startLabel;
@property (nonatomic, retain) UILabel *durationLabel;
@property (nonatomic, retain) UIButton *fullscreenButton;

// header bar
@property (nonatomic, retain) UIView *headerBar;
@property (nonatomic, retain) UIButton *lockButton;
@property (nonatomic, retain) UIButton *downloadButton;

@end

@interface WonderMovieFullscreenControlView (ProgressView) <WonderMovieProgressViewDelegate>

@end

@implementation WonderMovieFullscreenControlView
@synthesize delegate;
@synthesize controlState;

- (id)initWithFrame:(CGRect)frame autoPlayWhenStarted:(BOOL)autoPlayWhenStarted
{
    if (self = [super initWithFrame:frame]) {
        self.autoPlayWhenStarted = autoPlayWhenStarted;
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    self.backgroundColor = [UIColor clearColor];
    
    CGFloat bottomBarHeight = 40;
    CGFloat headerBarHeight = 40;
    CGFloat progressBarLeftPadding = 100;
    CGFloat progressBarRightPadding = 100;
    
    // Setup bottomBar
    self.bottomBar = [[[UIView alloc] initWithFrame:CGRectMake(0, self.height - bottomBarHeight, self.width, bottomBarHeight)] autorelease];
    self.bottomBar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.bottomBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.bottomBar];
    self.progressView = [[[WonderMovieProgressView alloc] initWithFrame:CGRectMake(progressBarLeftPadding, 0, self.bottomBar.width - progressBarLeftPadding - progressBarRightPadding, bottomBarHeight)] autorelease];
    self.progressView.delegate = self;
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
    self.startLabel.font = [UIFont systemFontOfSize:10];
    self.startLabel.backgroundColor = [UIColor clearColor];
    self.startLabel.textColor = [UIColor whiteColor];
    [self.bottomBar addSubview:self.startLabel];
    
    self.fullscreenButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.fullscreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    [self.fullscreenButton setTitle:@"F" forState:UIControlStateNormal];
    self.fullscreenButton.frame = CGRectMake(self.width - 45, 0, 40, bottomBarHeight);
    [self.bottomBar addSubview:self.fullscreenButton];
    
    self.durationLabel = [[[UILabel alloc] initWithFrame:CGRectMake(self.progressView.right + 5, 0, self.fullscreenButton.left - self.progressView.right - 5, bottomBarHeight)] autorelease];
    self.durationLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    self.durationLabel.font = [UIFont systemFontOfSize:10];
    self.durationLabel.backgroundColor = [UIColor clearColor];
    self.durationLabel.textColor = [UIColor whiteColor];
    [self.bottomBar addSubview:self.durationLabel];
    
    // Setup headerBar
    self.headerBar = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, headerBarHeight)] autorelease];
    self.headerBar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];    
    self.headerBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.headerBar];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [backButton setTitle:@"B" forState:UIControlStateNormal];
    backButton.frame = CGRectMake(0, 0, 40, 40);
    backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [backButton addTarget:self action:@selector(onClickBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:backButton];
    
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.downloadButton setTitle:@"D" forState:UIControlStateNormal];
    self.downloadButton.frame = CGRectMake(self.headerBar.width - 100, 0, 40, 40);
    self.downloadButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.downloadButton addTarget:self action:@selector(onClickDownload:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:self.downloadButton];
    
    self.lockButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.lockButton setTitle:@"L" forState:UIControlStateNormal];
    self.lockButton.frame = CGRectMake(self.width - 50, 0, 40, 40);
    self.lockButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;    
    [self.headerBar addSubview:self.lockButton];
    
    // Update control state
    if (self.autoPlayWhenStarted) {
        self.controlState = MovieControlStatePlaying;
    }
    else {
        self.controlState = MovieControlStateDefault;
    }
    [self updateActionState];
}

- (void)dealloc
{
    self.progressView = nil;
    self.bottomBar = nil;
    self.headerBar = nil;

    self.delegate = nil;
    [super dealloc];
}

#pragma mark State Manchine
- (void)handleCommand:(MovieControlCommand)cmd param:(id)param notify:(BOOL)notify
{
    NSLog(@"handleCommand %d, %@, %d", cmd, param, notify);
    if (cmd == MovieControlCommandEnd) {
        self.controlState = MovieControlStateEnded;
        
        if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceExit:)]) {
            [self.delegate movieControlSourceExit:self];
        }
    }
    else {
        switch (self.controlState) {
            case MovieControlStateDefault:
                if (cmd == MovieControlCommandPlay) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourcePlay:)]) {
                        [self.delegate movieControlSourcePlay:self];
                    }
                }
                break;
            case MovieControlStatePlaying:
                if (cmd == MovieControlCommandPause) {
                    self.controlState = MovieControlStatePaused;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourcePause:)]) {
                        [self.delegate movieControlSourcePause:self];
                    }
                }
                else if (cmd == MovieControlCommandSetProgress) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSource:setProgress:)]) {
                        [self.delegate movieControlSource:self setProgress:[(NSNumber *)param floatValue]];
                    }
                }
                else if (cmd == MovieControlCommandBuffer) {
                    self.controlState = MovieControlStateBuffering;
                    _bufferFromPaused = NO;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceBuffer:)]) {
                        [self.delegate movieControlSourceBuffer:self];
                    }
                }
                break;
            case MovieControlStateEnded:
                if (cmd == MovieControlCommandReplay) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceReplay:)]) {
                        [self.delegate movieControlSourceReplay:self];
                    }
                }
                break;
            case MovieControlStatePaused:
                if (cmd == MovieControlCommandPlay) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceResume:)]) {
                        [self.delegate movieControlSourceResume:self];
                    }
                }
                else if (cmd == MovieControlCommandSetProgress) {
                    self.controlState = MovieControlStatePaused;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSource:setProgress:)]) {
                        [self.delegate movieControlSource:self setProgress:[(NSNumber *)param floatValue]];
                    }
                }
                else if (cmd == MovieControlCommandBuffer) {
                    self.controlState = MovieControlStateBuffering;
                    _bufferFromPaused = YES;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceBuffer:)]) {
                        [self.delegate movieControlSourceBuffer:self];
                    }
                }
                break;
            case MovieControlStateBuffering:
                if (cmd == MovieControlCommandPlay) { // FIXME! Need it?
                    self.controlState = MovieControlStatePlaying;
                    
                    // Actually there is no need to notify since no internal operation will trigger buffer
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourcePlay:)]) {
                        [self.delegate movieControlSourcePlay:self];
                    }
                }
                else if (cmd == MovieControlCommandUnbuffer) {
                    if (_bufferFromPaused) {
                        self.controlState = MovieControlStatePaused;
                    }
                    else {
                        self.controlState = MovieControlStatePlaying;
                    }

                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceUnbuffer:)]) {
                        [self.delegate movieControlSourceUnbuffer:self];
                    }
                }
                break;
        }
    }
    
    // Update States
    [self updateActionState];
}

#pragma mark MovieControlSource
- (void)play
{
    [self handleCommand:MovieControlCommandPlay param:nil notify:NO];
}

- (void)pause
{
    [self handleCommand:MovieControlCommandPause param:nil notify:NO];
}

- (void)resume
{
    [self handleCommand:MovieControlCommandPlay param:nil notify:NO];
}

- (void)replay
{
    [self handleCommand:MovieControlCommandReplay param:nil notify:NO];
}

- (void)setProgress:(CGFloat)progress
{
    [self.progressView setProgress:progress];
    [self handleCommand:MovieControlCommandSetProgress param:@(progress) notify:NO];
}

- (void)buffer
{
    [self handleCommand:MovieControlCommandBuffer param:nil notify:NO];
}

- (void)unbuffer
{
    [self handleCommand:MovieControlCommandUnbuffer param:nil notify:NO];
}

- (void)end
{
    [self handleCommand:MovieControlCommandEnd param:nil notify:NO];
}

- (void)setPlaybackTime:(NSTimeInterval)playbackTime
{
    long time = playbackTime;
    int hour = time / 3600;
    int minute = time / 60 - hour * 60;
    int second = time % 60;
    self.startLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
}

- (void)setPlayableDuration:(NSTimeInterval)playableDuration
{
    if (_totalDuration > 0) {
        [self.progressView setCacheProgress:playableDuration / _totalDuration];
    }
}

- (void)setDuration:(NSTimeInterval)duration
{
    _totalDuration = duration;
    long time = duration;
    int hour = time / 3600;
    int minute = time / 60 - hour * 60;
    int second = time % 60;
    self.durationLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
}

#pragma mark UI Interaction
- (IBAction)onClickAction:(UIButton *)sender
{
    if (self.controlState == MovieControlStateDefault) {
        [self handleCommand:MovieControlCommandPlay param:nil notify:YES];
    }
    else if (self.controlState == MovieControlStatePlaying) {
        [self handleCommand:MovieControlCommandPause param:nil notify:YES];
    }
    else if (self.controlState == MovieControlStatePaused) {
        [self handleCommand:MovieControlCommandPlay param:nil notify:YES];
    }
    else if (self.controlState == MovieControlStateEnded) {
        [self handleCommand:MovieControlCommandReplay param:nil notify:YES];
    }
}

- (IBAction)onClickBack:(id)sender
{
    [self handleCommand:MovieControlCommandEnd param:nil notify:YES];
}

- (IBAction)onClickDownload:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(movieControlSource:setFullscreen:)]) {
        [self.delegate movieControlSource:self setFullscreen:NO];
    }
}

- (void)updateActionState
{
    NSArray *titles = @[@"default", @"playing", @"paused", @"buffering", @"ended"];
    [self.actionButton setTitle:titles[self.controlState] forState:UIControlStateNormal];
}

@end

@implementation WonderMovieFullscreenControlView (ProgressView)

- (void)wonderMovieProgressView:(WonderMovieProgressView *)progressView didChangeProgress:(CGFloat)progress
{
    [self handleCommand:MovieControlCommandSetProgress param:@(progress) notify:YES];
}

@end
