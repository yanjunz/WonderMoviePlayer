//
//  WonderMovieFullscreenControlView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WonderMovieFullscreenControlView.h"
#import "WonderMovieProgressView.h"
#import "UIView+Sizes.h"
#import "BatteryIconView.h"

@interface WonderMovieFullscreenControlView () {
    NSTimeInterval _playbackTime;
    NSTimeInterval _playableDuration;
    NSTimeInterval _duration;
    
    
    // for buffer loading
    BOOL _bufferFromPaused;
    BOOL _isLoading;
    NSTimeInterval _totalBufferingSize;
}
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) WonderMovieProgressView *progressView;
@property (nonatomic, retain) BatteryIconView *batteryView;
@property (nonatomic, retain) UILabel *timeLabel;

// bottom bar
@property (nonatomic, retain) UIView *bottomBar;
@property (nonatomic, retain) UIButton *actionButton;
@property (nonatomic, retain) UIButton *nextButton;
@property (nonatomic, retain) UILabel *startLabel;
@property (nonatomic, retain) UILabel *durationLabel;
//@property (nonatomic, retain) UIButton *fullscreenButton;

// header bar
@property (nonatomic, retain) UIView *headerBar;
@property (nonatomic, retain) UIButton *lockButton;
@property (nonatomic, retain) UIButton *downloadButton;

// buffering
@property (nonatomic, retain) UIView *loadingView;
@property (nonatomic, retain) UIImageView *loadingIndicator;
@property (nonatomic, retain) UILabel *loadingPercentLabel;
@property (nonatomic, retain) UILabel *loadingMessageLabel;

// center button
@property (nonatomic, retain) UIButton *replayButton;
@property (nonatomic, retain) UIButton *centerPlayButton;

// utils
@property (nonatomic, retain) NSArray *viewsToBeLocked;
@end

@interface WonderMovieFullscreenControlView (ProgressView) <WonderMovieProgressViewDelegate>

@end

@implementation WonderMovieFullscreenControlView
@synthesize delegate;
@synthesize controlState;

- (id)initWithFrame:(CGRect)frame autoPlayWhenStarted:(BOOL)autoPlayWhenStarted nextEnabled:(BOOL)nextEnabled
{
    if (self = [super initWithFrame:frame]) {
        _autoPlayWhenStarted = autoPlayWhenStarted;
        _nextEnabled = nextEnabled;
        self.autoresizesSubviews = YES;
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    self.backgroundColor = [UIColor clearColor];
    
    CGFloat bottomBarHeight = 50;
    CGFloat headerBarHeight = 44;
    CGFloat progressBarLeftPadding = self.nextEnabled ? 60+30 : 60;
    CGFloat progressBarRightPadding = 10;
    CGFloat durationLabelWidth = 100;
    CGFloat batteryHeight = 10;
    
    // Setup bottomBar
    self.bottomBar = [[[UIView alloc] initWithFrame:CGRectMake(0, self.height - bottomBarHeight, self.width, bottomBarHeight)] autorelease];
//    self.bottomBar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.bottomBar.backgroundColor = [UIColor colorWithPatternImage:QQImage(@"videoplayer_toolbar")];
    self.bottomBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.bottomBar];
    self.progressView = [[[WonderMovieProgressView alloc] initWithFrame:CGRectMake(progressBarLeftPadding, 0, self.bottomBar.width - progressBarLeftPadding - progressBarRightPadding, bottomBarHeight)] autorelease];
    self.progressView.delegate = self;
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.bottomBar addSubview:self.progressView];
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.actionButton setImage:QQImage(@"videoplayer_play_normal") forState:UIControlStateNormal];
    [self.actionButton setImage:QQImage(@"videoplayer_play_press") forState:UIControlStateHighlighted];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:10];
    self.actionButton.frame = CGRectMake(0, 0, 50, 50);
//    [self.actionButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(onClickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.actionButton];
    
    if (self.nextEnabled) {
        self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.nextButton setImage:QQImage(@"videoplayer_next_normal") forState:UIControlStateNormal];
        self.nextButton.frame = CGRectMake(progressBarLeftPadding - 38, (self.bottomBar.height - 17 * 2) / 2, 15 * 2, 17 * 2);
        [self.bottomBar addSubview:self.nextButton];
    }
    
    self.startLabel = [[[UILabel alloc] initWithFrame:CGRectMake(self.progressView.left, bottomBarHeight / 2, durationLabelWidth, bottomBarHeight / 2)] autorelease];
    self.startLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    self.startLabel.textAlignment = UITextAlignmentLeft;
    self.startLabel.font = [UIFont systemFontOfSize:10];
    self.startLabel.backgroundColor = [UIColor clearColor];
    self.startLabel.textColor = [UIColor whiteColor];
    [self.bottomBar addSubview:self.startLabel];
    
//    self.fullscreenButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    self.fullscreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
//    [self.fullscreenButton setTitle:@"F" forState:UIControlStateNormal];
//    self.fullscreenButton.frame = CGRectMake(self.width - 45, 0, 40, bottomBarHeight);
//    [self.bottomBar addSubview:self.fullscreenButton];
    
    self.durationLabel = [[[UILabel alloc] initWithFrame:CGRectMake(self.bottomBar.width - progressBarRightPadding - durationLabelWidth, self.startLabel.top, durationLabelWidth, bottomBarHeight / 2)] autorelease];
    self.durationLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    self.durationLabel.textAlignment = UITextAlignmentRight;
    self.durationLabel.font = [UIFont systemFontOfSize:10];
    self.durationLabel.backgroundColor = [UIColor clearColor];
    self.durationLabel.textColor = [UIColor whiteColor];
    [self.bottomBar addSubview:self.durationLabel];
    
    // Setup headerBar
    self.headerBar = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, headerBarHeight)] autorelease];
    self.headerBar.backgroundColor = [UIColor colorWithPatternImage:QQImage(@"videoplayer_headerbar")];
    self.headerBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.headerBar];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:QQImage(@"videoplayer_return") forState:UIControlStateNormal];
    backButton.frame = CGRectMake(0, 0, headerBarHeight, headerBarHeight);
    backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [backButton addTarget:self action:@selector(onClickBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:backButton];
    
    UIImageView *separatorView = [[[UIImageView alloc] initWithImage:QQImage(@"videoplayer_headerbar_separator")] autorelease];
    separatorView.center = CGPointMake(backButton.right, self.headerBar.height / 2);
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.headerBar addSubview:separatorView];
    
    separatorView = [[[UIImageView alloc] initWithImage:QQImage(@"videoplayer_headerbar_separator")] autorelease];
    separatorView.center = CGPointMake(self.width - backButton.right, self.headerBar.height / 2);
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.headerBar addSubview:separatorView];
    
    self.batteryView = [[[BatteryIconView alloc] initWithBatteryMonitoringEnabled:YES] autorelease];
    self.batteryView.frame = CGRectMake(self.headerBar.width - 10 - 24, headerBarHeight / 2, 24, batteryHeight);
    self.batteryView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.headerBar addSubview:self.batteryView];
    
    self.timeLabel = [[[UILabel alloc] initWithFrame:CGRectOffset(self.batteryView.frame, -2, -batteryHeight)] autorelease];
    self.timeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.timeLabel.textAlignment = UITextAlignmentCenter;
    self.timeLabel.textColor = [UIColor lightTextColor];
    self.timeLabel.backgroundColor = [UIColor clearColor];
    self.timeLabel.font = [UIFont systemFontOfSize:9];
    [self.headerBar addSubview:self.timeLabel];

    self.lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.lockButton setImage:QQImage(@"videoplayer_unlock") forState:UIControlStateNormal];
    [self.lockButton setImage:QQImage(@"videoplayer_locked") forState:UIControlStateSelected];
    self.lockButton.frame = CGRectMake(self.batteryView.left - 50, 0, headerBarHeight, headerBarHeight);
    self.lockButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.lockButton addTarget:self action:@selector(onClickLock:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:self.lockButton];

    self.downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.downloadButton setImage:QQImage(@"videoplayer_download") forState:UIControlStateNormal];
    self.downloadButton.frame = CGRectMake(self.lockButton.left - 50, 0, headerBarHeight, headerBarHeight);
    self.downloadButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.downloadButton addTarget:self action:@selector(onClickDownload:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:self.downloadButton];
    
    CGFloat centerButtonSize = 138 / 2;
    self.replayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.replayButton setImage:QQImage(@"videoplayer_replay") forState:UIControlStateNormal];
    self.replayButton.size = CGSizeMake(centerButtonSize, centerButtonSize);
    self.replayButton.center = self.center;
    self.replayButton.hidden = YES;
    self.replayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.replayButton addTarget:self action:@selector(onClickReplay:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.replayButton];
    
    self.centerPlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.centerPlayButton setImage:QQImage(@"videoplayer_play") forState:UIControlStateNormal];
    self.centerPlayButton.frame = self.replayButton.frame;
    self.centerPlayButton.hidden = YES;
    self.centerPlayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;    
    [self.centerPlayButton addTarget:self action:@selector(onClickPlay:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.centerPlayButton];
    
    self.viewsToBeLocked = @[backButton, self.downloadButton, self.bottomBar];
    
    // Update control state
    if (self.autoPlayWhenStarted) {
        self.controlState = MovieControlStatePlaying;
    }
    else {
        self.controlState = MovieControlStateDefault;
    }
    [self setupTimer];
    [self timerHandler]; // call to set info immediately
    [self updateActionState];
    LogFrame(self.frame);
    LogFrame(self.headerBar.frame);
    LogFrame(self.bottomBar.frame);
}

- (void)dealloc
{
    [self removeTimer];
    self.progressView = nil;
    self.bottomBar = nil;
    self.headerBar = nil;
    
    self.downloadButton = nil;
    self.lockButton = nil;
    self.actionButton = nil;
    self.nextButton = nil;
    
    self.batteryView = nil;
    self.timeLabel = nil;
    self.startLabel = nil;
    self.durationLabel = nil;
    
    self.loadingView = nil;
    self.loadingIndicator = nil;
    self.loadingMessageLabel = nil;
    self.loadingPercentLabel = nil;
    
    self.replayButton = nil;
    self.centerPlayButton = nil;
    
    self.viewsToBeLocked = nil;
    
    self.delegate = nil;

    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    NSLog(@"layoutSubviews");
    LogFrame([UIScreen mainScreen].applicationFrame);
    LogFrame(self.frame);
    LogFrame(self.headerBar.frame);    
    LogFrame(self.bottomBar.frame);
    LogFrame(self.loadingView.frame);
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

- (void)startLoading
{
    _isLoading = YES;
    NSLog(@"%@", self.loadingView.superview);
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
    _isLoading = NO;
    _totalBufferingSize = 0;
    
    [self.loadingView removeFromSuperview];
}

#pragma mark State Manchine
- (void)handleCommand:(MovieControlCommand)cmd param:(id)param notify:(BOOL)notify
{
//    NSLog(@"handleCommand %d, %@, %d", cmd, param, notify);
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
    
    [self startLoading];
}

- (void)unbuffer
{
    [self handleCommand:MovieControlCommandUnbuffer param:nil notify:NO];
    
    [self stopLoading];
}

- (void)end
{
    [self handleCommand:MovieControlCommandEnd param:nil notify:NO];
}

- (void)setPlaybackTime:(NSTimeInterval)playbackTime
{
    _playbackTime = playbackTime;
    long time = playbackTime;
    int hour = time / 3600;
    int minute = time / 60 - hour * 60;
    int second = time % 60;
    self.startLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
}

- (void)setPlayableDuration:(NSTimeInterval)playableDuration
{
    _playableDuration = playableDuration;
    if (_duration > 0) {
        [self.progressView setCacheProgress:playableDuration / _duration];
    }
    
    if (playableDuration < _playbackTime) {
        // loading
        if (_isLoading) {
            if (_totalBufferingSize <= 0) {
                _totalBufferingSize = _playbackTime - playableDuration;
            }
            
            CGFloat percent = 1 - ((_playbackTime - playableDuration) / _totalBufferingSize);
            self.loadingPercentLabel.text = [NSString stringWithFormat:@"%d%%", (int)(percent * 100)];
        }
    }
}

- (void)setDuration:(NSTimeInterval)duration
{
    _duration = duration;
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
//    if ([self.delegate respondsToSelector:@selector(movieControlSource:setFullscreen:)]) {
//        [self.delegate movieControlSource:self setFullscreen:NO];
//    }
    
    [self startLoading];
}

- (IBAction)onClickLock:(id)sender
{
    self.lockButton.selected = !self.lockButton.selected;
    for (UIView *view in self.viewsToBeLocked) {
        view.hidden = self.lockButton.selected;
    }
}

- (IBAction)onClickReplay:(id)sender
{
    [self handleCommand:MovieControlCommandReplay param:nil notify:YES];
}

- (IBAction)onClickPlay:(id)sender
{
    [self handleCommand:MovieControlCommandPlay param:nil notify:YES];
}

- (void)updateActionState
{
//    NSArray *titles = @[@"default", @"playing", @"paused", @"buffering", @"ended"];
//    [self.actionButton setTitle:titles[self.controlState] forState:UIControlStateNormal];
    if (self.controlState == MovieControlStateDefault ||
        self.controlState == MovieControlStatePlaying ||
        (self.controlState == MovieControlStateBuffering && !_bufferFromPaused)) {
        [self.actionButton setImage:QQImage(@"videoplayer_pause_normal") forState:UIControlStateNormal];
        [self.actionButton setImage:QQImage(@"videoplayer_pause_press") forState:UIControlStateHighlighted];
        self.centerPlayButton.hidden = YES;
        self.replayButton.hidden = YES;
    }
    else if (self.controlState == MovieControlStatePaused ||
             (self.controlState == MovieControlStateBuffering && _bufferFromPaused)) {
        [self.actionButton setImage:QQImage(@"videoplayer_play_normal") forState:UIControlStateNormal];
        [self.actionButton setImage:QQImage(@"videoplayer_play_press") forState:UIControlStateHighlighted];
        self.centerPlayButton.hidden = NO;
    }
    else if (self.controlState == MovieControlStateEnded) {
        // set replay
        [self.actionButton setImage:QQImage(@"videoplayer_play_normal") forState:UIControlStateNormal];
        [self.actionButton setImage:QQImage(@"videoplayer_play_press") forState:UIControlStateHighlighted];
        self.replayButton.hidden = NO;
    }
}

- (void)setupTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
}

- (void)removeTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)timerHandler
{
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"hh:mm";
    self.timeLabel.text = [df stringFromDate:date];
    [df release];
}

@end

@implementation WonderMovieFullscreenControlView (ProgressView)

- (void)wonderMovieProgressView:(WonderMovieProgressView *)progressView didChangeProgress:(CGFloat)progress
{
    [self handleCommand:MovieControlCommandSetProgress param:@(progress) notify:YES];
}

@end
