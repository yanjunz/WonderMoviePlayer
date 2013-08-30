//
//  WonderMovieFullscreenControlView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_MOVIE_PLAYER

#import <QuartzCore/QuartzCore.h>
#import "WonderMoviePlayerConstants.h"
#import "WonderMovieFullscreenControlView.h"
#import "WonderMovieProgressView.h"
#import "UIView+Sizes.h"
#import "BatteryIconView.h"

// y / x
#define kWonderMovieVerticalPanGestureCoordRatio    1.732050808f
#define kWonderMovieHorizontalPanGestureCoordRatio  1.0f
#define kWonderMoviePanDistanceThrehold             5.0f

@interface WonderMovieFullscreenControlView () {
    NSTimeInterval _playbackTime;
    NSTimeInterval _playableDuration;
    NSTimeInterval _duration;
    
    // for buffer loading
    BOOL _bufferFromPaused;
    BOOL _isLoading;
    NSTimeInterval _totalBufferingSize;
    
    // progress view
    BOOL _isProgressViewPanning; // flag to ignore msg to set progress when the progress view is dragging
}
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) WonderMovieProgressView *progressView;

// battery
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
@property (nonatomic, retain) UIButton *crossScreenButton;

// center button
@property (nonatomic, retain) UIButton *replayButton;
@property (nonatomic, retain) UIButton *centerPlayButton;

// utils
@property (nonatomic, retain) NSArray *viewsToBeLocked;

@property (nonatomic, retain) UIPanGestureRecognizer *panGestureRecognizer;
@end

@interface WonderMovieFullscreenControlView (ProgressView) <WonderMovieProgressViewDelegate>

@end

@interface WonderMovieFullscreenControlView (Gesture) <UIGestureRecognizerDelegate>

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
    self.downloadButton.frame = CGRectOffset(self.lockButton.frame, -50, 0); //CGRectMake(self.lockButton.left - 50, 0, headerBarHeight, headerBarHeight);
    self.downloadButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.downloadButton addTarget:self action:@selector(onClickDownload:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:self.downloadButton];
    
    self.crossScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.crossScreenButton setImage:QQImage(@"videoplayer_cross_screen") forState:UIControlStateNormal];
    self.crossScreenButton.frame = CGRectOffset(self.downloadButton.frame, -50, 0);
    self.crossScreenButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.crossScreenButton addTarget:self action:@selector(onClickCrossScreen:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:self.crossScreenButton];
    
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
    
    self.viewsToBeLocked = @[backButton, self.downloadButton, self.bottomBar, self.crossScreenButton];
    
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
}

- (void)installGestureHandlerForParentView
{
    // Setup tap GR
    UITapGestureRecognizer *tapGR = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapOverlayView:)] autorelease];
    tapGR.delegate = self;
    [self.superview addGestureRecognizer:tapGR];
    self.panGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanOverlayView:)] autorelease];
    [self.superview addGestureRecognizer:self.panGestureRecognizer];
}

- (void)dealloc
{
    [self removeTimer];
    self.progressView = nil;
    self.bottomBar = nil;
    self.headerBar = nil;
    
    self.downloadButton = nil;
    self.crossScreenButton = nil;
    self.lockButton = nil;
    self.actionButton = nil;
    self.nextButton = nil;
    
    self.batteryView = nil;
    self.timeLabel = nil;
    self.startLabel = nil;
    self.durationLabel = nil;
    
    
    
    self.replayButton = nil;
    self.centerPlayButton = nil;
    
    self.viewsToBeLocked = nil;
    
    self.delegate = nil;
    self.panGestureRecognizer = nil;

    [super dealloc];
}

#pragma mark Loading
- (void)startLoading
{
    _isLoading = YES;
    [self.infoView startLoading];
}

- (void)stopLoading
{
    _isLoading = NO;
    _totalBufferingSize = 0;
    [self.infoView stopLoading];
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
                else if (cmd == MovieControlCommandSetProgress) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSource:setProgress:)]) {
                        [self.delegate movieControlSource:self setProgress:[(NSNumber *)param floatValue]];
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
    if (!_isProgressViewPanning) {
        [self handleCommand:MovieControlCommandSetProgress param:@(progress) notify:NO];
    }
    else {
        long time = _duration * progress;
        int hour = time / 3600;
        int minute = time / 60 - hour * 60;
        int second = time % 60;
        self.infoView.progressTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
    }
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
            self.infoView.loadingPercentLabel.text = [NSString stringWithFormat:@"%d%%", (int)(percent * 100)];
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

- (CGFloat)getTimeControlWidth
{
    return self.progressView.width;
}

- (void)startToDownload
{
    self.downloadButton.enabled = NO;
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
    if ([self.delegate respondsToSelector:@selector(movieControlSourceOnDownload:)]) {
        [self.delegate movieControlSourceOnDownload:self];
    }
}

- (IBAction)onClickCrossScreen:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(movieControlSourceOnCrossScreen:)]) {
        [self.delegate movieControlSourceOnCrossScreen:self];
    }
}

- (IBAction)onClickLock:(id)sender
{
    self.lockButton.selected = !self.lockButton.selected;
    for (UIView *view in self.viewsToBeLocked) {
        view.hidden = self.lockButton.selected;
    }
    self.panGestureRecognizer.enabled = !self.lockButton.selected;
    
    if ([self.delegate respondsToSelector:@selector(movieControlSource:lock:)]) {
        [self.delegate movieControlSource:self lock:self.lockButton.selected];
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

#pragma mark Gesture handler
- (IBAction)onTapOverlayView:(UITapGestureRecognizer *)gr
{
    BOOL animationToHide = self.alpha > 0;
    [UIView animateWithDuration:0.5f animations:^{
        if (animationToHide) {
            self.alpha = 0;
        }
        else {
            self.alpha = 1;
        }
    }];
}

- (IBAction)onPanOverlayView:(UIPanGestureRecognizer *)gr
{
    static enum WonderMoviePanAction {
        WonderMoviePanAction_No,
        WonderMoviePanAction_Progress,
        WonderMoviePanAction_Volume,
        WonderMoviePanAction_Brigitness,
    } sPanAction = WonderMoviePanAction_No; // record the actual action of serial panning gesture
    
    CGPoint offset = [gr translationInView:gr.view];
    CGPoint loc = [gr locationInView:gr.view];
//    NSLog(@"pan %d, (%f,%f), (%f, %f)", gr.state, loc.x, loc.y, offset.x, offset.y);
    
    CGRect progressValidRegion = CGRectMake(0, self.headerBar.bottom, gr.view.width, gr.view.height - self.headerBar.bottom - self.bottomBar.height);
    
    if (fabs(offset.y) >= fabs(offset.x) * kWonderMovieVerticalPanGestureCoordRatio &&
        fabs(offset.y) > kWonderMoviePanDistanceThrehold)
    {
        // vertical pan gesture, should be treated for volume or brightness
        if (loc.x < gr.view.width * 0.4 &&
            (sPanAction == WonderMoviePanAction_No || sPanAction == WonderMoviePanAction_Brigitness))
        {
            // brightness
            sPanAction = WonderMoviePanAction_Brigitness;
            CGFloat inc = -offset.y / gr.view.height;
//            NSLog(@"pan Brightness %f, (%f, %f), %f", offset.y, loc.x, loc.y, inc);
            [self increaseBrightness:inc];
        }
        else if (loc.x > gr.view.width * 0.6 &&
                 (sPanAction == WonderMoviePanAction_No || sPanAction == WonderMoviePanAction_Volume))
        {
            // volume
            sPanAction = WonderMoviePanAction_Volume;
            CGFloat inc = -offset.y / gr.view.height;
//            NSLog(@"pan Volume %f, %f, %f", offset.y, gr.view.height, inc);
            [self increaseVolume:inc];
        }
        [gr setTranslation:CGPointZero inView:gr.view];
    }
    else if (fabs(offset.y) <= fabs(offset.x) * kWonderMovieHorizontalPanGestureCoordRatio &&
             CGRectContainsPoint(progressValidRegion, loc) &&
//             fabs(offset.x) > kWonderMoviePanDistanceThrehold &&
             (sPanAction == WonderMoviePanAction_No || sPanAction == WonderMoviePanAction_Progress))
    {
        // progress
        if (sPanAction == WonderMoviePanAction_No) { // just start
            [self beginScrubbing];
        }
        
        sPanAction = WonderMoviePanAction_Progress;
        CGFloat inc = offset.x / 10 ; // 1s for 10 pixel
//        NSLog(@"pan Progress %f, %f, %f, %f", offset.x, gr.view.width, inc, inc > 0 ? ceilf(inc) : floorf(inc));
        inc = inc > 0 ? ceilf(inc) : floorf(inc);
        [self increaseProgress:inc];
        [gr setTranslation:CGPointZero inView:gr.view];
    }
    
    // clear the action when gesture end
    if (gr.state == UIGestureRecognizerStateEnded) {
        if (sPanAction == WonderMoviePanAction_Progress) {
            [self endScrubbing];
        }
        sPanAction = WonderMoviePanAction_No;
    }
}

#pragma mark Update System Info
- (void)increaseVolume:(CGFloat)volume
{
    if ([self.delegate respondsToSelector:@selector(movieControlSource:increaseVolume:)]) {
        [self.delegate movieControlSource:self increaseVolume:volume];
    }
}

- (void)increaseBrightness:(CGFloat)brightness
{
    UIScreen *screen = [UIScreen mainScreen];
    CGFloat newBrightness = screen.brightness + brightness;
    newBrightness = MIN(1, MAX(newBrightness, 0));
    screen.brightness = newBrightness;
}

- (void)increaseProgress:(CGFloat)progressBySec
{
    double time = _playbackTime + progressBySec;
    time = MIN(_duration, MAX(time, 0));
    if (isfinite(time) && isfinite(_duration) && _duration > 0) {
//        NSLog(@"increaseProgress %f, %f, %f => %f", progressBySec, _playbackTime, _playbackTime/_duration, time /_duration);
        [self scrub:time / _duration];
        _playbackTime = time;
    }
}

- (void)beginScrubbing
{
    _isProgressViewPanning = YES;
    [self.infoView showProgressTime:YES animated:YES];
    if ([self.delegate respondsToSelector:@selector(movieControlSourceBeginChangeProgress:)]) {
        [self.delegate movieControlSourceBeginChangeProgress:self];
    }
}

- (void)scrub:(CGFloat)progress
{
    [self handleCommand:MovieControlCommandSetProgress param:@(progress) notify:YES];
    [self setProgress:progress];
}

- (void)endScrubbing
{
    _isProgressViewPanning = NO;
    [self.infoView showProgressTime:NO animated:YES];
    if ([self.delegate respondsToSelector:@selector(movieControlSourceEndChangeProgress:)]) {
        [self.delegate movieControlSourceEndChangeProgress:self];
    }
}

@end

@implementation WonderMovieFullscreenControlView (ProgressView)

- (void)wonderMovieProgressViewBeginChangeProgress:(WonderMovieProgressView *)progressView
{
//    NSLog(@"wonderMovieProgressViewBeginChangeProgress");
    [self beginScrubbing];
}

- (void)wonderMovieProgressView:(WonderMovieProgressView *)progressView didChangeProgress:(CGFloat)progress
{
//    NSLog(@"didChangeProgress %f", progress);
    [self scrub:progress];
}

- (void)wonderMovieProgressViewEndChangeProgress:(WonderMovieProgressView *)progressView;
{
//    NSLog(@"wonderMovieProgressViewEndChangeProgress");
    [self endScrubbing];
}

@end

@implementation WonderMovieFullscreenControlView (Gesture)


// Bugfix: button doesn't repsond to any click if there is UITapGestureRecognizer in superview
// http://stackoverflow.com/questions/13515539/uibutton-not-works-in-ios-5-x-everything-is-fine-in-ios-6-x
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return !([touch.view isKindOfClass:[UIControl class]]);
}

@end


#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER
