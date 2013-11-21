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
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TVDramaManager.h"
#import "WonderMovieDramaView.h"
#import "NSObject+Block.h"
#import "VideoGroup.h"
#import "VideoGroup+VideoDetailSet.h"
#import "Video.h"

#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
#import "AirPlayDetector.h"
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY

// y / x
#define kWonderMovieVerticalPanGestureCoordRatio    1.732050808f
#define kWonderMovieHorizontalPanGestureCoordRatio  1.0f
#define kWonderMoviePanDistanceThrehold             5.0f

#define kWonderMovieTagSeparatorAfterDownload       101
#define kWonderMovieTagSeparatorAfterTVDrama        102

#define kWonderMovieResolutionButtonTagBase         100

@interface WonderMovieFullscreenControlView () <UIGestureRecognizerDelegate>{
    NSTimeInterval _playbackTime;
    NSTimeInterval _playableDuration;
    NSTimeInterval _duration;
    
    // for buffer loading
    BOOL _bufferFromPaused;
    BOOL _isLoading;
    NSTimeInterval _totalBufferingSize;
    
    // scrubbing related
    BOOL _isScrubbing; // flag to ignore msg to set progress when scrubbing
    CGFloat _progressWhenStartScrubbing; // record the progress when begin to scrub
    CGFloat _accumulatedProgressBySec; // the total accumulated progress by second
    CGFloat _lastProgressToScrub;   // record the last progress to be set when scrubbing is ended
    
    BOOL _isDownloading;
    BOOL _hasStarted;
    
    BOOL _isLocked;
    
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    MPVolumeView *_airPlayButton; // assign
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    
    BOOL _resolutionsChanged;
    
    // tip
    BOOL _wasHorizontalPanningTipShown;
    BOOL _wasVerticalPanningTipShown;
}
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) WonderMovieProgressView *progressView;

@property (nonatomic, retain) UIView *contentView;

// bottom bar
@property (nonatomic, retain) UIView *bottomBar;
@property (nonatomic, retain) UIView *progressBar;
@property (nonatomic, retain) UIButton *actionButton;
@property (nonatomic, retain) UIButton *nextButton;
@property (nonatomic, retain) UILabel *startLabel;
@property (nonatomic, retain) UILabel *durationLabel;
//@property (nonatomic, retain) UIButton *fullscreenButton;

// header bar
@property (nonatomic, retain) UIView *headerBar;
@property (nonatomic, retain) UIButton *lockButton;
@property (nonatomic, retain) UIButton *downloadButton;
//@property (nonatomic, retain) UIButton *crossScreenButton;

@property (nonatomic, retain) UIButton *menuButton;
@property (nonatomic, retain) UIButton *tvDramaButton;

// title & subtitle
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *subtitleLabel;

// popup menu
@property (nonatomic, retain) UIView *popupMenu;
@property (nonatomic, retain) UIView *resolutionsView;
@property (nonatomic, retain) UIButton *resolutionButton;

// utils
@property (nonatomic, retain) NSArray *viewsToBeLocked;

@property (nonatomic, retain) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, retain) UIView *dramaContainerView;
@property (nonatomic, retain) WonderMovieDramaView *dramaView;

// Tip
@property (nonatomic, retain) UIView *horizontalPanningTipView;
@property (nonatomic, retain) UIView *verticalPanningTipView;
@end

@interface WonderMovieFullscreenControlView (ProgressView) <WonderMovieProgressViewDelegate>

@end

@interface WonderMovieFullscreenControlView (DramaView) <WonderMovieDramaViewDelegate>
- (void)dramaDidSelectSetNum:(int)setNum;
@end

@interface WonderMovieFullscreenControlView (Utils)
- (UIImage *)imageWithColor:(UIColor *)color;
- (UIImage *)backgroundImageWithSize:(CGSize)size content:(UIImage *)content;
@end

#pragma mark Tip

@interface WonderMovieFullscreenControlView (Tip)
- (void)loadTipStatus;
- (void)showHorizontalPanningTip:(BOOL)show;
- (void)showVerticalPanningTip:(BOOL)show;
- (BOOL)canShowHorizontalPanningTip;
- (BOOL)canShowVerticalPanningTip;

- (void)tryToShowVerticalPanningTip;
- (void)dismissProgressTipIfShown;
- (void)dismissVolumeTipIfShown;
@end


void wonderMovieVolumeListenerCallback (
                             void                      *inClientData,
                             AudioSessionPropertyID    inID,
                             UInt32                    inDataSize,
                             const void                *inData
                             ){
    
    if (inID != kAudioSessionProperty_CurrentHardwareOutputVolume) {
        return;
    }
    
    WonderMovieFullscreenControlView *bself = (WonderMovieFullscreenControlView *)inClientData;
    [bself performSelectorOnMainThread:@selector(tryToShowVerticalPanningTip) withObject:nil waitUntilDone:NO];
    
//    const float *volumePointer = inData;
//    float volume = *volumePointer;
//    NSLog(@"wonderMovieVolumeListenerCallback %d, %f", (unsigned int)inID, volume);
    
}

@implementation WonderMovieFullscreenControlView
@synthesize delegate;
@synthesize controlState;
@synthesize isLiveCast = _isLiveCast;
@synthesize resolutions = _resolutions;
@synthesize selectedResolutionIndex = _selectedResolutionIndex;
@synthesize tvDramaManager = _tvDramaManager;

//- (id)retain
//{
//    id r = [super retain];
//    NSLog(@"retain %d", [self retainCount]);
//    return r;
//}
//
//- (oneway void)release
//{
//    NSLog(@"release %d", [self retainCount]);
//    [super release];
//}

+ (void)initialize
{
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    [[AirPlayDetector defaultDetector] startMonitoring:[UIApplication sharedApplication].keyWindow];
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY
}

#pragma mark UIView LifeCycle
- (id)initWithFrame:(CGRect)frame autoPlayWhenStarted:(BOOL)autoPlayWhenStarted downloadEnabled:(BOOL)downloadEnabled crossScreenEnabled:(BOOL)crossScreenEnabled
{
    if (self = [super initWithFrame:frame]) {
        _autoPlayWhenStarted = autoPlayWhenStarted;
        _downloadEnabled = downloadEnabled;
        _crossScreenEnabled = crossScreenEnabled;
        self.autoresizesSubviews = YES;
        
        [self loadTipStatus];
    }
    return self;
}

- (void)dealloc
{
    [self removeTimer];
    
    self.contentView = nil;
    
    self.infoView = nil;
    
    self.progressView = nil;
    
    self.bottomBar = nil;
    self.progressBar = nil;
    self.actionButton = nil;
    self.nextButton = nil;
    self.startLabel = nil;
    self.durationLabel = nil;
    
    self.headerBar = nil;
    self.lockButton = nil;
    self.downloadButton = nil;
    //    self.crossScreenButton = nil;
    self.menuButton = nil;
    
    self.titleLabel = nil;
    self.subtitleLabel = nil;
    
    self.popupMenu = nil;
    self.resolutionsView = nil;
    self.resolutionButton = nil;
    
    self.viewsToBeLocked = nil;
    
    self.delegate = nil;
    self.panGestureRecognizer = nil;
    
    self.horizontalPanningTipView = nil;
    self.verticalPanningTipView = nil;
    
    self.tvDramaManager = nil;
    self.dramaContainerView = nil;
    self.dramaView = nil;
    [super dealloc];
}

#pragma mark UIView Layout
- (void)setupView
{
    NSMutableArray *lockedViews = [NSMutableArray array];
    
    self.backgroundColor = [UIColor clearColor];
    
    // all controls add to contentView
    UIView *contentView = [[UIView alloc] initWithFrame:self.bounds];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.backgroundColor = [UIColor clearColor];
    self.contentView = contentView;
    [self addSubview:self.contentView];
    [contentView release];
    
    CGFloat bottomBarHeight = 50;
    CGFloat headerBarHeight = 44;
    CGFloat progressBarLeftPadding = (YES ? 60+15+10 : 60) + 8 - 10;
    CGFloat progressBarRightPadding = 0;
    CGFloat durationLabelWidth = 100;
    
    // Setup bottomBar
    UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.height - bottomBarHeight, self.width, bottomBarHeight)];
    self.bottomBar = bottomBar;
    [bottomBar release];
    
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_HIDE_BOTTOMBAR_UNTIL_STARTED
    self.bottomBar.top = self.bottom; // hide bottom bar until movie started
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_HIDE_BOTTOMBAR_UNTIL_STARTED
    self.bottomBar.userInteractionEnabled = NO;
    
//    self.bottomBar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.bottomBar.backgroundColor = [UIColor colorWithPatternImage:QQVideoPlayerImage(@"toolbar")];
    self.bottomBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [contentView addSubview:self.bottomBar];
    
    UIView *progressBar = [[UIView alloc] initWithFrame:CGRectMake(progressBarLeftPadding, 0, self.bottomBar.width - progressBarLeftPadding - progressBarRightPadding, bottomBarHeight)];
    self.progressBar = progressBar;
    self.progressBar.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.bottomBar addSubview:progressBar];
    [progressBar release];
    
    CGFloat resolutionButtonWidth = 32 + 20 * 2, resolutionButtonHeight = 18 + 20, resolutionButtonPadding = 25 - 20;
    UIButton *resolutionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    resolutionButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    resolutionButton.titleLabel.font = [UIFont systemFontOfSize:11];
    UIImage *bgImage = [self backgroundImageWithSize:CGSizeMake(resolutionButtonWidth, resolutionButtonHeight) content:QQVideoPlayerImage(@"resolution_button_selected")];
    [resolutionButton setBackgroundImage:bgImage forState:UIControlStateNormal];
    [resolutionButton addTarget:self action:@selector(onClickResolution:) forControlEvents:UIControlEventTouchUpInside];
    self.resolutionButton = resolutionButton;
    resolutionButton.frame = CGRectMake(progressBar.width - resolutionButtonPadding - resolutionButtonWidth, (progressBar.height - resolutionButtonHeight) / 2, resolutionButtonWidth, resolutionButtonHeight);
    [progressBar addSubview:resolutionButton];
    
    WonderMovieProgressView *progressView = [[WonderMovieProgressView alloc] initWithFrame:CGRectMake(0, 0, progressBar.width - resolutionButtonPadding * 2 - resolutionButtonWidth + kProgressViewPadding, progressBar.height)];
    self.progressView = progressView;
    [progressView release];
    
    self.progressView.delegate = self;
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    if (self.isLiveCast) {
        self.progressView.userInteractionEnabled = NO;
    }
    [progressBar addSubview:self.progressView];
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.actionButton setImage:QQVideoPlayerImage(@"play_normal") forState:UIControlStateNormal];
    [self.actionButton setImage:QQVideoPlayerImage(@"play_press") forState:UIControlStateHighlighted];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:10];
    self.actionButton.frame = CGRectMake(8, 0, 50, 50);
    [self.actionButton addTarget:self action:@selector(onClickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.actionButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextButton setImage:QQVideoPlayerImage(@"next_normal") forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(onClickNext:) forControlEvents:UIControlEventTouchUpInside];
    self.nextButton.frame = CGRectMake(progressBarLeftPadding - 20 - 6, (self.bottomBar.height - 17 * 2) / 2, 15 * 2, 17 * 2);
    [self.bottomBar addSubview:self.nextButton];
    
    UILabel *startLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.progressView.left + kProgressViewPadding, bottomBarHeight / 2 + 2, durationLabelWidth, bottomBarHeight / 2)];
    self.startLabel = startLabel;
    [startLabel release];
    self.startLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    self.startLabel.textAlignment = UITextAlignmentLeft;
    self.startLabel.font = [UIFont systemFontOfSize:10];
    self.startLabel.backgroundColor = [UIColor clearColor];
    self.startLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    [progressBar addSubview:self.startLabel];
    
    UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.progressView.right - progressBarRightPadding - durationLabelWidth - kProgressViewPadding, self.startLabel.top, durationLabelWidth, bottomBarHeight / 2)];
    self.durationLabel = durationLabel;
    [durationLabel release];
    self.durationLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
    self.durationLabel.textAlignment = UITextAlignmentRight;
    self.durationLabel.font = [UIFont systemFontOfSize:10];
    self.durationLabel.backgroundColor = [UIColor clearColor];
    self.durationLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    [progressBar addSubview:self.durationLabel];
    
    CGFloat statusBarHeight = 20;
    
    // Setup headerBar
    UIView *headerBar = [[UIView alloc] initWithFrame:CGRectMake(0, statusBarHeight, self.width, headerBarHeight)];
    self.headerBar = headerBar;
    [headerBar release];
    self.headerBar.backgroundColor = [UIColor colorWithPatternImage:QQVideoPlayerImage(@"headerbar")];
    self.headerBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [contentView addSubview:self.headerBar];
    
    UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, -statusBarHeight, self.width, statusBarHeight)];
    statusBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    statusBarView.backgroundColor = [UIColor colorWithPatternImage:QQVideoPlayerImage(@"statusbar_bg")];
    [self.headerBar addSubview:statusBarView];
    [statusBarView release];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:QQVideoPlayerImage(@"back") forState:UIControlStateNormal];
    backButton.frame = CGRectMake(2, 0, 53, headerBarHeight);
    backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [backButton addTarget:self action:@selector(onClickBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:backButton];
    
    UIImageView *separatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"headerbar_separator")];
    separatorView.center = CGPointMake(backButton.right, self.headerBar.height / 2);
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.headerBar addSubview:separatorView];
    [lockedViews addObject:separatorView];
    [separatorView release];
    
    CGFloat buttonWidth = 60;
    CGFloat headerBarRightPadding = 0;//5;
    CGFloat buttonFontSize = 13;
    UIFont *buttonFont = [UIFont systemFontOfSize:buttonFontSize];
    UIImage *highlightedImage = [self imageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0.15]];
    
    self.menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.menuButton.frame = CGRectMake(self.headerBar.width - headerBarRightPadding - buttonWidth, 0, buttonWidth, headerBarHeight);
    self.menuButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.menuButton setTitle:NSLocalizedString(@"菜单", nil) forState:UIControlStateNormal];
    self.menuButton.titleLabel.font = buttonFont;
    [self.menuButton addTarget:self action:@selector(onClickMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self.menuButton setBackgroundImage:highlightedImage forState:UIControlStateSelected];
    [self.headerBar addSubview:self.menuButton];
    CGRect btnRect = self.menuButton.frame;
    
    self.tvDramaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tvDramaButton.frame = CGRectOffset(btnRect, -buttonWidth+1, 0);
    self.tvDramaButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.tvDramaButton setTitle:NSLocalizedString(@"剧集", nil) forState:UIControlStateNormal];
    self.tvDramaButton.titleLabel.font = buttonFont;
    [self.tvDramaButton addTarget:self action:@selector(onClickTVDrama:) forControlEvents:UIControlEventTouchUpInside];
    [self.tvDramaButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self.headerBar addSubview:self.tvDramaButton];
    btnRect = self.tvDramaButton.frame;
    
    separatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"headerbar_separator")];
    separatorView.center = CGPointMake(self.tvDramaButton.right, self.headerBar.height / 2);
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    separatorView.tag = kWonderMovieTagSeparatorAfterTVDrama;
    [self.headerBar addSubview:separatorView];
    [separatorView release];
    
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.downloadButton.frame = CGRectOffset(btnRect, -buttonWidth+1, 0);
    self.downloadButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.downloadButton setTitle:NSLocalizedString(@"缓存", nil) forState:UIControlStateNormal];
    [self.downloadButton setTitleColor:QQColor(videoplayer_downloaded_color) forState:UIControlStateDisabled];
    self.downloadButton.titleLabel.font = buttonFont;
    [self.downloadButton addTarget:self action:@selector(onClickDownload:) forControlEvents:UIControlEventTouchUpInside];
    [self.downloadButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self.headerBar addSubview:self.downloadButton];
//    btnRect = self.downloadButton.frame;
    
    separatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"headerbar_separator")];
    separatorView.center = CGPointMake(self.downloadButton.right, self.headerBar.height / 2);
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    separatorView.tag = kWonderMovieTagSeparatorAfterDownload;
    [self.headerBar addSubview:separatorView];
    [separatorView release];
    
    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(backButton.right + 1 + 9, 0, (self.downloadButton.left - (backButton.right + 1 + 9) - 20) * 3.f / 4, headerBarHeight)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.textColor = QQColor(videoplayer_title_color);
    titleLabel.font = [UIFont systemFontOfSize:13];
    titleLabel.text = @"";
    [self.headerBar addSubview:titleLabel];
    self.titleLabel = titleLabel;
    [titleLabel release];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:self.titleLabel.frame];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    subtitleLabel.textColor = QQColor(videoplayer_subtitle_color);
    subtitleLabel.font = [UIFont systemFontOfSize:11];
    subtitleLabel.text = @"";
    [self.headerBar addSubview:subtitleLabel];
    self.subtitleLabel = subtitleLabel;
    [subtitleLabel release];
    
    [self showResolutionButton:NO];
//    self.resolutions = @[@"高清", @"流畅", @"标清"];
//    [self rebuildResolutionsView];
//    [self updateResolutions];
    
    

    [lockedViews addObject:self.headerBar];
    [lockedViews addObject:self.bottomBar];
    self.viewsToBeLocked = lockedViews;
    
    // Update control state
    if (self.autoPlayWhenStarted) {
        self.controlState = MovieControlStatePlaying;
    }
    else {
        self.controlState = MovieControlStateDefault;
    }
    [self setupTimer];
//    [self timerHandler]; // call to set info immediately
    [self updateStates];
    
#ifdef MTT_TWEAK_WONDER_MOVIE_HIDE_SYSTEM_VOLUME_VIEW
    // Hide default volume view
    // http://stackoverflow.com/questions/7868457/applicationmusicplayer-volume-notification
    [self addSubview:[[[MPVolumeView alloc] initWithFrame:CGRectMake(-10000, -10000, 0, 0)] autorelease]];
#endif // MTT_TWEAK_WONDER_MOVIE_HIDE_SYSTEM_VOLUME_VIEW
    
    WonderMovieInfoView *infoView = [[WonderMovieInfoView alloc] initWithFrame:[self suggestedInfoViewFrame]];
    infoView.backgroundColor = [UIColor clearColor];
    infoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.infoView = infoView;
    [self addSubview:infoView];
    [infoView release];
    [self installGestureHandlers];
    
    [self showDramaButton:NO animated:NO];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // relayout title & subtitle
    CGFloat gapWidth = 7;
    CGFloat headerBarHeight = self.headerBar.height;
    CGFloat maxTitleWidth = self.downloadButton.left - self.titleLabel.left - gapWidth;
    CGFloat maxSubtitleWidth = maxTitleWidth * 1 / 4;
    self.titleLabel.size = CGSizeMake(maxTitleWidth, headerBarHeight);
    self.subtitleLabel.size = self.titleLabel.size;
    [self.titleLabel sizeToFit];
    [self.subtitleLabel sizeToFit];
    BOOL truncateTitle = NO, truncateSubtitle = NO;
    if (self.titleLabel.width + self.subtitleLabel.width > maxTitleWidth) {
        if (self.subtitleLabel.width > maxSubtitleWidth) {
            truncateSubtitle = YES;
            if (self.titleLabel.width > maxTitleWidth - maxSubtitleWidth) {
                truncateTitle = YES;
            }
        }
        else {
            truncateTitle = YES;
        }
    }
    
    // 1. truncate subtitle for maxSubtitleWidth
    if (truncateSubtitle) {
        if (truncateTitle) {
            self.subtitleLabel.width = maxSubtitleWidth;
        }
        else {
            self.subtitleLabel.width = maxTitleWidth - self.titleLabel.width;
        }
    }
    
    // 2. truncate title for the remaining space
    if (truncateTitle) {
        self.titleLabel.size = CGSizeMake(maxTitleWidth - self.subtitleLabel.width, headerBarHeight);
    }
    else {
        self.titleLabel.height = headerBarHeight;
    }
    self.subtitleLabel.frame = CGRectMake(self.titleLabel.right + gapWidth, 0, self.subtitleLabel.width, headerBarHeight);
    
    // layout resolutions
    if (_resolutionsChanged) {
        [self showResolutionButton:self.resolutions.count > 0];
        [self rebuildResolutionsView];
        [self updateResolutions];
    }
}

- (void)installGestureHandlers
{
    // Setup tap GR
    UITapGestureRecognizer *singleTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTapOverlayView:)];
    singleTapGR.delegate = self;
    singleTapGR.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTapGR];
    [singleTapGR release];
    
    UITapGestureRecognizer *doubleTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTapOverlayView:)];
    doubleTapGR.delegate = self;
    doubleTapGR.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTapGR];
    [doubleTapGR release];
    
    [singleTapGR requireGestureRecognizerToFail:doubleTapGR];
    
    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanOverlayView:)];
    self.panGestureRecognizer = panGR;
    [self addGestureRecognizer:self.panGestureRecognizer];
    [panGR release];
}

- (void)setInfoView:(WonderMovieInfoView *)infoView
{
    if (_infoView != infoView) {
        [_infoView.replayButton removeTarget:self action:@selector(onClickReplay:) forControlEvents:UIControlEventTouchUpInside];
        [_infoView.centerPlayButton removeTarget:self action:@selector(onClickPlay:) forControlEvents:UIControlEventTouchUpInside];
        [_infoView release];
        _infoView = [infoView retain];
        [_infoView.replayButton addTarget:self action:@selector(onClickReplay:) forControlEvents:UIControlEventTouchUpInside];
        [_infoView.centerPlayButton addTarget:self action:@selector(onClickPlay:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (CGRect)suggestedInfoViewFrame
{
    return CGRectMake(0, self.headerBar.bottom, self.width, self.height - self.headerBar.bottom - self.bottomBar.height);
}


- (void)setIsLiveCast:(BOOL)isLiveCast
{
    _isLiveCast = isLiveCast;
    self.progressView.userInteractionEnabled = !isLiveCast;
    self.downloadButton.enabled = ![self isDownloading] && !isLiveCast;
}

#pragma mark PopupMenu
- (UIView *)popupMenu
{
    if (_popupMenu == nil) {
        // popup menu
        CGFloat menuButtonHeight = 42;
        CGFloat menuSeparatorHeight = 1;
        CGFloat menuWidth = 97;
        CGFloat topOffset = -1;
        CGFloat buttonFontSize = 13;
        UIFont *buttonFont = [UIFont systemFontOfSize:buttonFontSize];
        UIImage *highlightedImage = [self imageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0.15]];
        CGFloat menuHeight = menuButtonHeight * 2 + menuSeparatorHeight;
        UIView *popupMenu = [[UIView alloc] initWithFrame:CGRectMake(self.width - menuWidth, -menuHeight, menuWidth, menuHeight)];
        
        popupMenu.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        popupMenu.backgroundColor = [UIColor clearColor];
        [self.infoView addSubview:popupMenu];
        _popupMenu = popupMenu;
        
        UIImageView *popupMenuBgImageView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"popup_menu_bg")];
        popupMenuBgImageView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
        popupMenuBgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        popupMenuBgImageView.frame = popupMenu.bounds;
        [popupMenu addSubview:popupMenuBgImageView];
        [popupMenuBgImageView release];
        
        UIButton *lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
        lockButton.frame = CGRectMake(0, topOffset, menuWidth, menuButtonHeight);
        lockButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        lockButton.titleLabel.font = buttonFont;
        [lockButton setTitle:NSLocalizedString(@"锁屏", nil) forState:UIControlStateNormal];
        [lockButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
        [lockButton addTarget:self action:@selector(onClickLock:) forControlEvents:UIControlEventTouchUpInside];
        [popupMenu addSubview:lockButton];
        
        UIImageView *menuSeparatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"separator_line")];
        menuSeparatorView.frame = CGRectMake(0, lockButton.bottom, menuWidth, menuSeparatorHeight);
        [popupMenu addSubview:menuSeparatorView];
        [menuSeparatorView release];
        
        UIButton *crossButton = [UIButton buttonWithType:UIButtonTypeCustom];
        crossButton.frame = CGRectOffset(lockButton.frame, 0, menuButtonHeight + menuSeparatorHeight);
        crossButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        crossButton.titleLabel.font = buttonFont;
        [crossButton setTitle:NSLocalizedString(@"跨屏分享", nil) forState:UIControlStateNormal];
        [crossButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
        [crossButton addTarget:self action:@selector(onClickCrossScreen:) forControlEvents:UIControlEventTouchUpInside];
        [popupMenu addSubview:crossButton];
    }
    return _popupMenu;
}

#pragma mark Resolutions
// resolutions popup view shoule be rebuilded if count of resolutons changed
- (void)rebuildResolutionsView
{
    CGFloat menuButtonHeight = 42;
    CGFloat menuSeparatorHeight = 1;
    CGFloat menuWidth = 67;
    CGFloat topOffset = 1;
    CGFloat buttonWidth = 32, buttonHeight = 18;
    int count = self.resolutions.count - 1;
    count = MAX(count, 0);
    
    if (_resolutionsView) {
        [_resolutionsView removeFromSuperview];
        [_resolutionsView release];
    }
    
    UIView *popupMenu = [[UIView alloc] initWithFrame:CGRectMake(self.width, topOffset, menuWidth, menuButtonHeight * count + menuSeparatorHeight + topOffset)];
    popupMenu.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    popupMenu.backgroundColor = [UIColor clearColor];
    [self.infoView addSubview:popupMenu];
    _resolutionsView = popupMenu;
    
    UIImageView *popupMenuBgImageView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"popup_menu_bg")];
    popupMenuBgImageView.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
    popupMenuBgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    popupMenuBgImageView.frame = popupMenu.bounds;
    [popupMenu addSubview:popupMenuBgImageView];
    [popupMenuBgImageView release];
    
    CGFloat x = 17;
    for (int i = 0; i < count; ++i) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat y = i * (menuButtonHeight + menuSeparatorHeight);
        
        button.frame = CGRectMake(x, y + 12 , buttonWidth, buttonHeight);
        button.tag = kWonderMovieResolutionButtonTagBase + i;
        button.titleLabel.font = [UIFont systemFontOfSize:11];
        [button setBackgroundImage:QQVideoPlayerImage(@"resolution_button_normal") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(onClickResolution:) forControlEvents:UIControlEventTouchUpInside];
        [popupMenu addSubview:button];
        
        UIImageView *menuSeparatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"separator_line")];
        menuSeparatorView.frame = CGRectMake(0, y + menuButtonHeight, menuWidth, menuSeparatorHeight);
        [popupMenu addSubview:menuSeparatorView];
        [menuSeparatorView release];
    }
    
    popupMenu.hidden = YES;
}

- (void)updateResolutions
{
    int tagIndex = 0;
    for (int i = 0; i < self.resolutions.count; ++i) {
        if (i == self.selectedResolutionIndex) {
            continue;
        }
        
        int tag = kWonderMovieResolutionButtonTagBase + tagIndex;
        UIButton *button = (UIButton *)[_resolutionsView viewWithTag:tag];
        [button setTitle:self.resolutions[i] forState:UIControlStateNormal];
        tagIndex ++;
    }
    if (self.resolutions.count > 0 && self.selectedResolutionIndex >= 0 && self.selectedResolutionIndex < self.resolutions.count) {
        [self.resolutionButton setTitle:self.resolutions[self.selectedResolutionIndex] forState:UIControlStateNormal];
    }
}

- (void)setResolutions:(NSArray *)resolutions
{
    if (_resolutions != resolutions) {
        [_resolutions release];
        
        _resolutions = [resolutions copy];
        _resolutionsChanged = YES;
        [self setNeedsLayout];
    }
}

- (void)showResolutionButton:(BOOL)show
{
    CGFloat resolutionButtonWidth = 32 + 20 * 2, resolutionButtonPadding = 25 - 20;
    CGFloat duration = 0.2f;
    if (show && self.resolutionButton.hidden) {
        // show
        self.resolutionButton.hidden = NO;
        [UIView animateWithDuration:duration animations:^{
            self.progressView.frame = CGRectMake(0, 0, self.progressBar.width - resolutionButtonPadding * 2 - resolutionButtonWidth + kProgressViewPadding, self.progressBar.height);
            self.durationLabel.right = self.progressView.right - kProgressViewPadding;
        }];
    }
    else if (!show && !self.resolutionButton.hidden) {
        // hide
        self.resolutionButton.hidden = YES;
        [UIView animateWithDuration:duration animations:^{
            self.progressView.frame = CGRectMake(0, 0, self.progressBar.width, self.progressBar.height);
            self.durationLabel.right = self.progressView.right - kProgressViewPadding;
        }];
    }
}

#pragma mark Lock
- (UIButton *)lockButton
{
    if (_lockButton == nil) {
        CGFloat headerBarHeight = self.headerBar.height;
        UIButton *lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [lockButton setImage:QQVideoPlayerImage(@"locked") forState:UIControlStateNormal];
        [lockButton setImage:QQVideoPlayerImage(@"unlock") forState:UIControlStateSelected];
        lockButton.frame = CGRectMake(self.width - headerBarHeight - 10, 20, headerBarHeight, headerBarHeight);
        lockButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [lockButton addTarget:self action:@selector(onClickLock:) forControlEvents:UIControlEventTouchUpInside];
        lockButton.alpha = 0;
        [self.contentView addSubview:lockButton];
        _lockButton = [lockButton retain];
    }
    return _lockButton;
}


#pragma mark Loading
- (void)startLoading
{
    // set the flag so that loading indicator can be resumed after play from pause
    _isLoading = YES;
    
    // If it is paused or ended, don't show loading indicator
    if ((self.controlState != MovieControlStatePaused && self.controlState != MovieControlStateEnded &&
        !(self.controlState == MovieControlStateBuffering && _bufferFromPaused)) ||
        self.controlState == MovieControlStateDefault
        ) {
        [self.infoView startLoading];
    }
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
//    NSArray *cmds = @[@"play", @"pause", @"end", @"replay", @"setProgress", @"buffer", @"unbuffer"];
//    NSArray *states = @[@"default", @"playing", @"paused", @"buffering", @"ended"];
//    if (cmd != MovieControlCommandSetProgress) {
//        NSLog(@"handleCommand cmd=%@, state=%@, %@, %d", cmds[cmd], states[self.controlState], param, notify);
//    }
    
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
                else if (cmd == MovieControlCommandSetProgress &&
                         [(NSNumber *)param floatValue] != 1) // iOS5 issue: setProgress cmd will be issued after the movie is end, just skip it
                {
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
                else if (cmd == MovieControlCommandPause) {
                    self.controlState = MovieControlStatePaused;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourcePause:)]) {
                        [self.delegate movieControlSourcePause:self];
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
//    if (cmd != MovieControlCommandSetProgress) {
//        NSLog(@"state = %d", self.controlState);
//    }
    // Update States
    [self updateStates];
    

    if (!_hasStarted && self.controlState == MovieControlStatePlaying) {
        [self onPlayingStarted];
    }
}

- (void)onPlayingStarted
{
    _hasStarted = YES; // start to play now, should show bottom bar
    
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_HIDE_BOTTOMBAR_UNTIL_STARTED
    [UIView animateWithDuration:0.5f animations:^{
        self.bottomBar.bottom = self.bottom;
    }];
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_HIDE_BOTTOMBAR_UNTIL_STARTED
    self.bottomBar.userInteractionEnabled = YES;
    
    [self cancelPreviousAndPrepareToDimControl];
    
    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume ,
                                    wonderMovieVolumeListenerCallback,
                                    self
                                    );
}

#pragma mark MovieControlSource
- (void)installControlSource
{
    [self setupView];
    
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAirPlayAvailabilityChanged) name:AirPlayAvailabilityChanged object:nil];
    [self onAirPlayAvailabilityChanged]; // Check it at once
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY
}

- (void)uninstallControlSource
{
    [self removeTimer];
    
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AirPlayAvailabilityChanged object:nil];
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, wonderMovieVolumeListenerCallback, self);
}

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle
{
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    [self setNeedsLayout];
}

- (void)prepareToPlay
{
    [self loadDramaInfo];
}

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
    [self handleCommand:MovieControlCommandSetProgress param:@(progress) notify:NO];
    
    // will not set progress when scrubbing
    if (!_isScrubbing) {
        [self.progressView setProgress:progress];
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
            percent = MAX(0, MIN(1, percent));
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

- (void)setBufferProgress:(CGFloat)progress
{
    progress = MAX(0, MIN(1, progress));
    self.infoView.loadingPercentLabel.text = [NSString stringWithFormat:@"%d%%", (int)(progress * 100)];
}

- (void)setBufferTitle:(NSString *)title
{
    self.infoView.loadingMessageLabel.text = title;
}

- (void)resetBufferTitle
{
    self.infoView.loadingMessageLabel.text = NSLocalizedString(@" 正在缓冲...", @"");
}

- (void)startToDownload
{
    self.downloadButton.enabled = NO;
    _isDownloading = YES;
}

- (void)finishDownload
{
    _isDownloading = NO;
    [self.downloadButton setTitle:NSLocalizedString(@"已缓存", nil) forState:UIControlStateNormal];
    self.downloadButton.enabled = NO;
}

- (void)setDownloadProgress:(CGFloat)progress
{
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"缓存 %d%%", nil), (int)(progress * 100)];
    [self.downloadButton setTitle:title forState:UIControlStateNormal];
}

- (BOOL)isDownloading
{
    return _isDownloading;
}

- (void)setBrightness:(CGFloat)brightness
{
    [self.infoView showBrightness:brightness];
}

- (void)setVolume:(CGFloat)volume
{
    [self.infoView showVolume:volume];
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
    else if (self.controlState == MovieControlStateBuffering) {
        if (_bufferFromPaused) {
            [self handleCommand:MovieControlCommandPlay param:nil notify:YES];
        }
        else {
            [self handleCommand:MovieControlCommandPause param:nil notify:YES];
        }
    }

    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickBack:(id)sender
{
    [self handleCommand:MovieControlCommandEnd param:nil notify:YES];
}

- (IBAction)onClickDownload:(id)sender
{
    [self dismissAllPopupViews];
    if ([self.delegate respondsToSelector:@selector(movieControlSourceOnDownload:)]) {
        [self.delegate movieControlSourceOnDownload:self];
    }
    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickCrossScreen:(id)sender
{
    [self dismissAllPopupViews];
    if ([self.delegate respondsToSelector:@selector(movieControlSourceOnCrossScreen:)]) {
        [self.delegate movieControlSourceOnCrossScreen:self];
    }
    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickLock:(id)sender
{
    _isLocked = !_isLocked;
    BOOL isLocked = _isLocked;
    self.panGestureRecognizer.enabled = !isLocked;
    [self dismissAllPopupViews];
    [UIView animateWithDuration:0.2f animations:^{
        for (UIView *view in self.viewsToBeLocked) {
            view.alpha = isLocked ? 0 : 1;
        }
        if (!isLocked) {
            self.lockButton.alpha = 0;
        }
    } completion:^(BOOL finished) {
        if (isLocked) {
            self.lockButton.alpha = 1;
            [self bringSubviewToFront:self.lockButton];
        }
    }];
    if ([self.delegate respondsToSelector:@selector(movieControlSource:lock:)]) {
        [self.delegate movieControlSource:self lock:self.lockButton.selected];
    }
    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickReplay:(id)sender
{
    [self handleCommand:MovieControlCommandReplay param:nil notify:YES];
    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickPlay:(id)sender
{
    [self handleCommand:MovieControlCommandPlay param:nil notify:YES];
    [self cancelPreviousAndPrepareToDimControl];    
}

- (IBAction)onClickMenu:(UIButton *)sender
{
    [self showPopupMenu:!self.menuButton.selected];
    [self cancelPreviousAndPrepareToDimControl];
}

- (void)showPopupMenu:(BOOL)show
{
    self.menuButton.selected = show;
    BOOL isShowed = self.popupMenu.bottom > 0;
    if (isShowed == show) {
        return;
    }

    [UIView animateWithDuration:0.5f animations:^{
        if (show) {
            self.popupMenu.top = -1;
            self.popupMenu.alpha = 1;
        }
        else {
            self.popupMenu.bottom = 0;
            self.popupMenu.alpha = 0;
        }
    }];
}

- (IBAction)onClickNext:(id)sender
{
    VideoGroup *videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
    if (self.tvDramaManager.curSetNum > 0 && videoGroup) {
        Video *nextVideo = [videoGroup videoAtSetNum:@(self.tvDramaManager.curSetNum + 1)];
        if (nextVideo) {
            [self dramaDidSelectSetNum:nextVideo.setNum.intValue];
        }
        else {
            NSLog(@"Warnning: There no next video");
        }
    }
}

- (IBAction)onClickTVDrama:(id)sender
{
    [self showOverlay:NO];
    [self showDramaView:YES];
    [self dismissAllPopupViews]; 
    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickResolution:(id)sender
{
    BOOL animateToShow = self.resolutionsView.hidden;
    [self showResolutionView:animateToShow];
    [self cancelPreviousAndPrepareToDimControl];
}

- (void)showResolutionView:(BOOL)show
{
    if (self.resolutionsView.superview != self.infoView) {
        [self.resolutionsView removeFromSuperview];
        [self.infoView addSubview:self.resolutionsView];
    }
    CGPoint pt = [self.infoView convertPoint:self.resolutionButton.center fromView:self.resolutionButton.superview];
    self.resolutionsView.left = pt.x - self.resolutionsView.width / 2;
    if (show) {
        self.resolutionsView.top = self.infoView.height;
        self.resolutionsView.hidden = NO;
    }
    [UIView animateWithDuration:0.5 animations:^{
        if (show) {
            self.resolutionsView.bottom = self.infoView.height;
            self.resolutionsView.alpha = 1;
        }
        else {
            self.resolutionsView.top = self.infoView.height;
            self.resolutionsView.alpha = 0;
        }
    } completion:^(BOOL finished) {
        if (!show) {
            self.resolutionsView.hidden = YES;
        }
    }];
}

- (void)dismissAllPopupViews
{
    [self showPopupMenu:NO];
    [self showResolutionView:NO];
}

#pragma mark InfoView update
- (void)updateStates
{
    if (self.controlState == MovieControlStateDefault ||
        self.controlState == MovieControlStatePlaying ||
        (self.controlState == MovieControlStateBuffering && !_bufferFromPaused)) {
        [self.actionButton setImage:QQVideoPlayerImage(@"pause_normal") forState:UIControlStateNormal];
        [self.actionButton setImage:QQVideoPlayerImage(@"pause_press") forState:UIControlStateHighlighted];
        self.infoView.centerPlayButton.hidden = YES;
        self.infoView.replayButton.hidden = YES;
    }
    else if (self.controlState == MovieControlStatePaused ||
             (self.controlState == MovieControlStateBuffering && _bufferFromPaused)) {
        [self.actionButton setImage:QQVideoPlayerImage(@"play_normal") forState:UIControlStateNormal];
        [self.actionButton setImage:QQVideoPlayerImage(@"play_press") forState:UIControlStateHighlighted];
        self.infoView.centerPlayButton.hidden = _isLoading;
        self.infoView.replayButton.hidden = YES;
    }
    else if (self.controlState == MovieControlStateEnded) {
        // set replay
        [self.actionButton setImage:QQVideoPlayerImage(@"play_normal") forState:UIControlStateNormal];
        [self.actionButton setImage:QQVideoPlayerImage(@"play_press") forState:UIControlStateHighlighted];
        self.infoView.replayButton.hidden = NO;
        self.infoView.centerPlayButton.hidden = YES;
        _isLoading = NO; // clear loading flag
        
        [self showOverlay:YES];
        [self showDramaView:NO];
    }
    
    if (_isLoading) { // continue to loading
        [self startLoading];
    }
    else {
        [self stopLoading];
    }
}

- (void)updateInfoViewProgress:(CGFloat)progress
{
    long time = _duration * progress;
    int hour = time / 3600;
    int minute = time / 60 - hour * 60;
    int second = time % 60;
    if (hour > 0) {
        self.infoView.progressTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
    }
    else {
        self.infoView.progressTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    }
}

#pragma mark Timer to update timeLabel in bettery
- (void)setupTimer
{
    // for update the date time above battery
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
}

- (void)removeTimer
{
//    if (self.timer) {
//        [self.timer invalidate];
//        self.timer = nil;
//    }
}

//- (void)timerHandler
//{
//    NSDate *date = [NSDate date];
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    df.dateFormat = @"hh:mm";
//    self.timeLabel.text = [df stringFromDate:date];
//    [df release];
//}

#pragma mark Gesture handler
- (IBAction)onSingleTapOverlayView:(UITapGestureRecognizer *)gr
{
    BOOL animationToHide = self.contentView.alpha > 0;
    [self showOverlay:!animationToHide];
    [self cancelPreviousAndPrepareToDimControl];
}

- (void)showOverlay:(BOOL)show
{
    BOOL animationToHide = !show;
    if ([self.delegate respondsToSelector:@selector(movieControlSource:showControlView:)]) {
        [self.delegate movieControlSource:self showControlView:!animationToHide];
    }
    [UIView animateWithDuration:animationToHide ? kWonderMovieControlDimDuration : kWonderMovieControlShowDuration animations:^{
        if (animationToHide) {
            self.contentView.alpha = 0;
        }
        else {
            self.contentView.alpha = 1;
        }
    }];
    if (animationToHide) {
        [self dismissAllPopupViews];
    }
}

- (IBAction)onDoubleTapOverlayView:(UITapGestureRecognizer *)gr
{
    if ([self.delegate respondsToSelector:@selector(movieControlSourceSwitchVideoGravity:)]) {
        [self.delegate movieControlSourceSwitchVideoGravity:self];
    }
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
            
            [self dismissVolumeTipIfShown];
        }
        [gr setTranslation:CGPointZero inView:gr.view];
    }
    else if (fabs(offset.y) <= fabs(offset.x) * kWonderMovieHorizontalPanGestureCoordRatio &&
             CGRectContainsPoint(progressValidRegion, loc) &&
//             fabs(offset.x) > kWonderMoviePanDistanceThrehold &&
             (sPanAction == WonderMoviePanAction_No || sPanAction == WonderMoviePanAction_Progress))
    {
        if (_hasStarted) {
            // progress
            if (sPanAction == WonderMoviePanAction_No) { // just start
                [self beginScrubbing];
                if (self.controlState == MovieControlStateBuffering && _lastProgressToScrub >= 0 && isfinite(_lastProgressToScrub)) {
                    _progressWhenStartScrubbing = _lastProgressToScrub;
                }
                else {
                    _progressWhenStartScrubbing = self.progressView.progress;
                }
            }
            
            sPanAction = WonderMoviePanAction_Progress;
            CGFloat inc = offset.x * 1 / 10 ; // 1s for 10 pixel
//          NSLog(@"pan Progress %f, %f, %f, %f", offset.x, gr.view.width, inc, inc > 0 ? ceilf(inc) : floorf(inc));
            inc = inc > 0 ? ceilf(inc) : floorf(inc);
//            [self increaseProgress:inc];
            [self accumulateProgress:inc];
        }
        
        [gr setTranslation:CGPointZero inView:gr.view];
    }
    
    // clear the action when gesture end
    if (gr.state == UIGestureRecognizerStateEnded) {
        if (sPanAction == WonderMoviePanAction_Progress) {
            CGFloat newProgress = _progressWhenStartScrubbing + _accumulatedProgressBySec / _duration;
            newProgress = MIN(MAX(0, newProgress), 1);
            _progressWhenStartScrubbing = 0;
            _accumulatedProgressBySec = 0;
            [self endScrubbing:newProgress];
            
            [self dismissProgressTipIfShown];
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
    [self cancelPreviousAndPrepareToDimControl];
}

- (void)increaseBrightness:(CGFloat)brightness
{
//    UIScreen *screen = [UIScreen mainScreen];
//    CGFloat newBrightness = screen.brightness + brightness;
//    newBrightness = MIN(1, MAX(newBrightness, 0));
//    screen.brightness = newBrightness;
    
    if ([self.delegate respondsToSelector:@selector(movieControlSource:increaseBrightness:)]) {
        [self.delegate movieControlSource:self increaseBrightness:brightness];
    }
    [self cancelPreviousAndPrepareToDimControl];
}

- (void)accumulateProgress:(CGFloat)progressBySec
{
    _accumulatedProgressBySec += progressBySec;
    CGFloat newProgress = _progressWhenStartScrubbing + _accumulatedProgressBySec / _duration;
    newProgress = MIN(MAX(0, newProgress), 1);
//    NSLog(@"accumulateProgress %f,%f,%f", _accumulatedProgressBySec, _progressWhenStartScrubbing, newProgress);
    // update UI
    [self updateInfoViewProgress:newProgress];
    [self cancelPreviousAndPrepareToDimControl];
}


- (void)beginScrubbing
{
//    NSLog(@"control.beginScrubbing");
    _isScrubbing = YES;
    [self.infoView showProgressTime:YES animated:YES];
    if ([self.delegate respondsToSelector:@selector(movieControlSourceBeginChangeProgress:)]) {
        [self.delegate movieControlSourceBeginChangeProgress:self];
    }
    [self cancelPreviousAndPrepareToDimControl];    
}

- (void)scrub:(CGFloat)progress
{
//    NSLog(@"control.scrub %f", progress);
    [self handleCommand:MovieControlCommandSetProgress param:@(progress) notify:YES];
    [self setProgress:progress];
    [self updateInfoViewProgress:progress];
    [self cancelPreviousAndPrepareToDimControl];
}

- (void)endScrubbing:(CGFloat)progress
{
//    NSLog(@"control.endScrubbing %f", progress);
    _isScrubbing = NO;
    _lastProgressToScrub = progress;
    [self.infoView showProgressTime:NO animated:YES];
    if ([self.delegate respondsToSelector:@selector(movieControlSource:endChangeProgress:)]) {
        [self.delegate movieControlSource:self endChangeProgress:progress];
    }
    [self cancelPreviousAndPrepareToDimControl];
}

- (void)cancelPreviousAndPrepareToDimControl
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dimControl) object:nil];
    [self performSelector:@selector(dimControl) withObject:nil afterDelay:5.0f];
}

- (void)dimControl
{
    if (self.contentView.alpha == 1 && self.controlState != MovieControlStatePaused && self.controlState != MovieControlStateEnded && !_isScrubbing) {
        if ([self.delegate respondsToSelector:@selector(movieControlSource:showControlView:)]) {
            [self.delegate movieControlSource:self showControlView:NO];
        }
        [UIView animateWithDuration:kWonderMovieControlDimDuration animations:^{
            self.contentView.alpha = 0;
        }];
        [self dismissAllPopupViews];
    }
}

#pragma mark AirPlay
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
- (void)onAirPlayAvailabilityChanged
{
    BOOL isAirPlayAvailable = [AirPlayDetector defaultDetector].isAirPlayAvailable;
    
    // has added but airplay is not available, airplay button should be removed
    if (_airPlayButton && !isAirPlayAvailable) {
        [_airPlayButton removeFromSuperview];
        _airPlayButton = nil;
        self.progressBar.width = self.bottomBar.width - self.progressBar.left;
    }
    // airplay became available and no airplay button yet, just add one
    else if (_airPlayButton == nil && isAirPlayAvailable) {
        MPVolumeView *volumeView = [[MPVolumeView alloc] init] ;
        volumeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
//        volumeView.backgroundColor = [UIColor redColor];
        [volumeView setShowsVolumeSlider:NO];
        [volumeView sizeToFit];
        [self.bottomBar addSubview:volumeView];
        _airPlayButton = volumeView;
        CGFloat delta = volumeView.width + 5;
        self.progressBar.width = self.bottomBar.width - self.progressBar.left - delta;
        volumeView.left = self.progressBar.right - 5;
        volumeView.center = CGPointMake(volumeView.center.x, self.bottomBar.height / 2);
        [volumeView release];
    }
}
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY


- (UIView *)horizontalPanningTipView
{
    if (_horizontalPanningTipView == nil) {
        UIView *tipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 181, 38)];
        tipView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        tipView.backgroundColor = [UIColor clearColor];
        
        UIImageView *bgImageView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"progress_prompt_bg")];
        [tipView addSubview:bgImageView];
        [bgImageView release];
        
        UIImageView *circleView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"progress_prompt_circle")];
        [tipView addSubview:circleView];
        [circleView release];
        
        UIImageView *fingerView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"progress_prompt_gesture")];
        [tipView addSubview:fingerView];
        [fingerView release];
        
        // add animation
        CGFloat delta = 16;
        circleView.origin = CGPointMake(27 - delta, 0);
        fingerView.origin = CGPointMake(circleView.left - 2.5, 0);
        
        [UIView animateWithDuration:1.6f delay:0 options:UIViewAnimationOptionRepeat animations:^{
            circleView.left += delta * 2;
            fingerView.left += delta * 2;
        } completion:nil];
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
            circleView.alpha = 0.1;
        } completion:nil];
        
        _horizontalPanningTipView = tipView;
    }
    return _horizontalPanningTipView;
}

- (UIView *)verticalPanningTipView
{
    if (_verticalPanningTipView == nil) {
        UIView *tipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38, 181)];
        tipView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        tipView.backgroundColor = [UIColor clearColor];
        
        UIImageView *bgImageView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"volume_prompt_bg")];
        [tipView addSubview:bgImageView];
        [bgImageView release];
        
        UIImageView *circleView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"volume_prompt_circle")];
        [tipView addSubview:circleView];
        [circleView release];
        
        UIImageView *fingerView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"volume_prompt_gesture")];
        [tipView addSubview:fingerView];
        [fingerView release];
        
        // add animation
        CGFloat delta = 16;
        circleView.origin = CGPointMake(0, 27 - delta);
        fingerView.origin = CGPointMake(0, circleView.top - 2.5);
        
        [UIView animateWithDuration:1.6f delay:0 options:UIViewAnimationOptionRepeat animations:^{
            circleView.top += delta * 2;
            fingerView.top += delta * 2;
        } completion:nil];
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
            circleView.alpha = 0.1;
        } completion:nil];
        
        _verticalPanningTipView = tipView;
    }
    return _verticalPanningTipView;
}

#pragma mark Drama View
- (void)showDramaView:(BOOL)show
{
    if (show || _isLocked) {
        self.panGestureRecognizer.enabled = NO;
    }
    else {
        self.panGestureRecognizer.enabled = YES;
    }
    
    if (self.dramaContainerView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.userInteractionEnabled = YES;
        self.dramaContainerView = view;
        [view release];
        
        view.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapDramaView:)];
        tapGR.delegate = self;
        [view addGestureRecognizer:tapGR];
        [tapGR release];
        
        CGFloat width = 326;
        WonderMovieDramaView *dramaView = [[WonderMovieDramaView alloc] initWithFrame:CGRectMake(self.width - width, 0, width, self.height)];
        dramaView.tvDramaManager = self.tvDramaManager;
        dramaView.delegate = self;
        [view addSubview:dramaView];
        self.dramaView = dramaView;
        [dramaView release];
        
        view.left = self.width;
    }
    
    if (self.dramaContainerView.superview != self) {
        [self addSubview:self.dramaContainerView];
    }
    if (show) {
        [self.dramaView reloadData];
    }

    [UIView animateWithDuration:0.5 animations:^{
        if (show) {
            self.dramaContainerView.left = 0;
        }
        else {
            self.dramaContainerView.left = self.width;
        }
    } completion:^(BOOL finished) {
        if (!show) {
            [self.dramaContainerView removeFromSuperview];
        }
    }];
}

- (IBAction)onTapDramaView:(id)sender
{
    [self showOverlay:YES];
    [self showDramaView:NO];
}

- (void)loadDramaInfo
{
    [self.tvDramaManager getDramaInfo:TVDramaRequestTypeCurrent completionBlock:^(BOOL success) {
        if (success) {
            [self performSelectorOnMainThread:@selector(finishLoadDramaInfo) withObject:nil waitUntilDone:NO];
        }
        else {
            [self performSelectorOnMainThread:@selector(failLoadDramaInfo) withObject:nil waitUntilDone:NO];
        }
    }];
}

- (void)finishLoadDramaInfo
{
    [self showDramaButton:YES animated:YES];
}

- (void)failLoadDramaInfo
{
    [self showDramaButton:NO animated:YES];
}

- (void)showDramaButton:(BOOL)show animated:(BOOL)animated
{
    BOOL needShow = show && self.tvDramaButton.hidden;
    BOOL needHide = !show && !self.tvDramaButton.hidden;
    CGFloat progressBarLeftPaddingForShowNext = (60+15+10) + 8 - 10;
    CGFloat progressBarLeftPaddingForHideNext = (60) + 8 - 10;
    
    [UIView animateWithDuration:animated ? 0.5f : 0 animations:^{
        if (needShow) {
            self.downloadButton.right = self.tvDramaButton.left + 1;
            self.progressBar.frame = CGRectMake(progressBarLeftPaddingForShowNext, self.progressBar.top, self.progressBar.width - (progressBarLeftPaddingForShowNext - progressBarLeftPaddingForHideNext), self.progressBar.height);
        }
        else if (needHide) {
            self.downloadButton.right = self.menuButton.left + 1;
            self.progressBar.frame = CGRectMake(progressBarLeftPaddingForHideNext, self.progressBar.top, self.progressBar.width + (progressBarLeftPaddingForShowNext - progressBarLeftPaddingForHideNext), self.progressBar.height);
        }
    } completion:^(BOOL finished) {
        if (needShow) {
            self.tvDramaButton.hidden = NO;
            UIView *separatorView = [self.headerBar viewWithTag:kWonderMovieTagSeparatorAfterDownload];
            separatorView.hidden = NO;
            self.nextButton.hidden = NO;
        }
        else if (needHide) {
            self.tvDramaButton.hidden = YES;
            UIView *separatorView = [self.headerBar viewWithTag:kWonderMovieTagSeparatorAfterDownload];
            separatorView.hidden = YES;
            self.nextButton.hidden = YES;
        }
    }];
}

#pragma mark UIGestureRecognizerDelegate
// Bugfix: button doesn't repsond to any click if there is UITapGestureRecognizer in superview
// http://stackoverflow.com/questions/13515539/uibutton-not-works-in-ios-5-x-everything-is-fine-in-ios-6-x
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return !([touch.view isKindOfClass:[UIControl class]]) && !(self.dramaView && [touch.view isDescendantOfView:self.dramaView]);
}

@end


@implementation WonderMovieFullscreenControlView (ProgressView)

- (void)wonderMovieProgressViewBeginChangeProgress:(WonderMovieProgressView *)progressView
{
//    NSLog(@"wonderMovieProgressViewBeginChangeProgress");
    if (_hasStarted) {
        [self beginScrubbing];
    }
}

- (void)wonderMovieProgressView:(WonderMovieProgressView *)progressView didChangeProgress:(CGFloat)progress
{
//    NSLog(@"didChangeProgress %f", progress);
//    [self scrub:progress];
    [self updateInfoViewProgress:progress];
}

- (void)wonderMovieProgressViewEndChangeProgress:(WonderMovieProgressView *)progressView;
{
//    NSLog(@"wonderMovieProgressViewEndChangeProgress");
    [self endScrubbing:progressView.progress];
    
    if ([self canShowHorizontalPanningTip]) {
        [self showHorizontalPanningTip:YES];
    }
}

@end

@implementation WonderMovieFullscreenControlView (Utils)

- (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)backgroundImageWithSize:(CGSize)size content:(UIImage *)content
{
    CGRect rect = CGRectZero;
    rect.size = size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, rect);
    
    CGRect imageRect = CGRectMake((size.width - content.size.width) / 2, (size.height - content.size.height) / 2, content.size.width, content.size.height);
    CGContextSetShouldAntialias(context, YES);
    
    [content drawInRect:imageRect];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

static NSString *kWonderMovieHorizontalPanningTipKey = @"kWonderMovieHorizontalPanningTipKey";
static NSString *kWonderMovieVerticalPanningTipKey = @"kWonderMovieVerticalPanningTipKey";
@implementation WonderMovieFullscreenControlView (Tip)

- (void)loadTipStatus
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    _wasHorizontalPanningTipShown = [ud boolForKey:kWonderMovieHorizontalPanningTipKey];
    _wasVerticalPanningTipShown = [ud boolForKey:kWonderMovieVerticalPanningTipKey];
}

- (void)showHorizontalPanningTip:(BOOL)show
{
    if (!show && !_wasHorizontalPanningTipShown && _horizontalPanningTipView.superview == self.infoView) {
        _wasHorizontalPanningTipShown = YES;
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:@(_wasHorizontalPanningTipShown) forKey:kWonderMovieHorizontalPanningTipKey];
        [ud synchronize];
        
        // Hide tip view
        [UIView animateWithDuration:0.2f animations:^{
            self.horizontalPanningTipView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.horizontalPanningTipView removeFromSuperview];
        }];
    }
    else if (show && _horizontalPanningTipView.superview != self.infoView) {
        // Show tip view
        self.horizontalPanningTipView.center = CGPointMake(self.infoView.width / 2, 18 + self.horizontalPanningTipView.height / 2);
        [self.infoView addSubview:self.horizontalPanningTipView];
        
        
        // automatically dismiss progress tip after 5s if no any action
        [self performSelector:@selector(dismissProgressTipIfShown) withObject:nil afterDelay:5];
    }
}

- (void)showVerticalPanningTip:(BOOL)show
{
    if (!show && !_wasVerticalPanningTipShown && _verticalPanningTipView.superview == self.infoView) {
        _wasVerticalPanningTipShown = YES;
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:@(_wasVerticalPanningTipShown) forKey:kWonderMovieVerticalPanningTipKey];
        [ud synchronize];
        
        // Hide tip view
        [UIView animateWithDuration:0.2f animations:^{
            self.verticalPanningTipView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.verticalPanningTipView removeFromSuperview];
        }];
    }
    else if (show && _verticalPanningTipView.superview != self.infoView) {
        // Show tip view
        self.verticalPanningTipView.center = CGPointMake(self.infoView.width - 20 - self.verticalPanningTipView.width / 2, self.infoView.height / 2);
        [self.infoView addSubview:self.verticalPanningTipView];
        
        // automatically dismiss volume tip after 5s if no any action
        [self performSelector:@selector(dismissVolumeTipIfShown) withObject:nil afterDelay:5];
    }
}

- (BOOL)canShowHorizontalPanningTip
{
    return !_wasHorizontalPanningTipShown;
}

- (BOOL)canShowVerticalPanningTip
{
    return !_wasVerticalPanningTipShown;
}

- (void)dismissProgressTipIfShown
{
    [self showHorizontalPanningTip:NO];
}

- (void)dismissVolumeTipIfShown
{
    [self showVerticalPanningTip:NO];
}

- (void)tryToShowVerticalPanningTip
{
    if ([self canShowVerticalPanningTip]) {
        [self showVerticalPanningTip:YES];
    }
}

@end

@implementation WonderMovieFullscreenControlView (DramaView)

- (void)wonderMovieDramaView:(WonderMovieDramaView *)dramaView didSelectSetNum:(int)setNum
{
    [self showOverlay:YES];
    [self showDramaView:NO];
    
    [self dramaDidSelectSetNum:setNum];
}

- (void)dramaDidSelectSetNum:(int)setNum
{
    if ([self.delegate respondsToSelector:@selector(movieControlSource:willPlayVideoGroup:setNum:)]) {
        [self.delegate movieControlSource:self willPlayVideoGroup:[self.tvDramaManager videoGroupInCurrentThread] setNum:setNum];
    }
    
    self.tvDramaManager.curSetNum = setNum;
    self.tvDramaManager.webURL = [[self.tvDramaManager videoGroupInCurrentThread] videoAtSetNum:@(setNum)].url;
    
//    [self performBlockInBackground:^{
//        BOOL ret = [self.tvDramaManager sniffVideoSource];
//        [self performBlock:^{
//            if (ret) {
//                [self dramaDidFinishSniff:setNum];
//            }
//            else {
//                [self dramaDidFailToSniff];
//            }
//        } afterDelay:0];
//    }];
    
    [self.tvDramaManager sniffVideoSource:^(BOOL success) {
        // make sure to invoke UI related code in main thread
        [self performBlock:^{
            NSLog(@"fullscreen sniffVideoSource %d", success);
            if (success) {
                [self dramaDidFinishSniff:setNum];
            }
            else {
                [self dramaDidFailToSniff];
            }
        } afterDelay:0];
    }];
}

- (void)dramaDidFinishSniff:(int)setNum
{
    if ([self.delegate respondsToSelector:@selector(movieControlSource:didPlayVideoGroup:setNum:)]) {
        [self.delegate movieControlSource:self didPlayVideoGroup:[self.tvDramaManager videoGroupInCurrentThread] setNum:setNum];
    }
}

- (void)dramaDidFailToSniff
{
    if ([self.delegate respondsToSelector:@selector(movieControlSourceFailToPlayVideoGroup:)]) {
        [self.delegate movieControlSourceFailToPlayVideoGroup:self];
    }
}

@end


#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER
