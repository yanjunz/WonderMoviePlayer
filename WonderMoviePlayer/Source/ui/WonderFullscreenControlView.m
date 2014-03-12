//
//  WonderFullscreenControlView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_MOVIE_PLAYER

#import <QuartzCore/QuartzCore.h>
#import "WonderMoviePlayerConstants.h"
#import "WonderFullscreenControlView.h"
#import "WonderFullscreenControlView+StateMachine.h"
#import "WonderProgressView.h"
#import "UIView+Sizes.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TVDramaManager.h"
#import "WonderMovieDramaView.h"
#import "NSObject+Block.h"
#import "VideoGroup.h"
#import "VideoGroup+Additions.h"
#import "Video.h"
#import "VideoHistoryOperator.h"
#import "VideoBookmarkOperator.h"
#import "UIImage+FillColor.h"
#import "WonderFullScreenBottomView.h"

#define kWonderMovieAirplayLeftPadding                  5

// y / x
#define kWonderMovieVerticalPanGestureCoordRatio    1.732050808f
//#define kWonderMovieHorizontalPanGestureCoordRatio  1.0f
#define kWonderMovieHorizontalPanGestureCoordRatio  0.6f
#define kWonderMoviePanDistanceThrehold             5.0f

#define kWonderMovieTagSeparatorBeforeMyVideo       101
#define kWonderMovieTagSeparatorAfterMyVideo        102
#define kWonderMovieTagSeparatorAfterTVDrama        103

#define kWonderMovieResolutionButtonTagBase         100

@interface WonderMovieResolutionButton : UIButton

@end

@interface WonderFullscreenControlView () <UIGestureRecognizerDelegate>{
    
    CGFloat _downloadProgress;
}
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) WonderProgressView *progressView;

@property (nonatomic, strong) UIView *contentView;

// bottom bar
@property (nonatomic, strong) UIView *bottomBarContainer;
@property (nonatomic, strong) WonderFullScreenBottomView *bottomView;

// header bar
@property (nonatomic, strong) UIView *headerBar;
@property (nonatomic, strong) UIButton *lockButton;

@property (nonatomic, strong) UIButton *menuButton;
@property (nonatomic, strong) UIButton *tvDramaButton;
@property (nonatomic, strong) UIButton *myVideoButton;

// title & subtitle
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

// popup menu
@property (nonatomic, strong) UIView *popupMenu;
@property (nonatomic, strong) UIView *resolutionsView;

// utils
@property (nonatomic, strong) NSArray *viewsToBeLocked;

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic, strong) UIView *dramaContainerView;
@property (nonatomic, strong) WonderMovieDramaView *dramaView;

// Tip
@property (nonatomic, strong) UIView *horizontalPanningTipView;
@property (nonatomic, strong) UIView *verticalPanningTipView;

@property (nonatomic, strong) UIView *errorView;

- (void)tryToSetVolume:(NSNumber *)volume;
@end

@interface WonderFullscreenControlView (ProgressView) <WonderProgressViewDelegate>

@end

@interface WonderFullscreenControlView (DramaView) <WonderMovieDramaViewDelegate>
- (void)dramaDidSelectSetNum:(int)setNum;
- (void)prepareToPlayNextDrama;
- (void)playNextDrama;
@end


#pragma mark Tip

@interface WonderFullscreenControlView (Tip)
- (void)loadTipStatus;
- (void)showHorizontalPanningTip:(BOOL)show;
- (void)showVerticalPanningTip:(BOOL)show;
- (BOOL)canShowHorizontalPanningTip;
- (BOOL)canShowVerticalPanningTip;

- (void)tryToShowVerticalPanningTip;
- (void)dismissProgressTipIfShown;
- (void)dismissVolumeTipIfShown;
- (void)dismissBrightnessTipIfShown;
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
    
    WonderFullscreenControlView *bself = (__bridge WonderFullscreenControlView *)inClientData;
    [bself performSelectorOnMainThread:@selector(tryToShowVerticalPanningTip) withObject:nil waitUntilDone:NO];
    
    const float *volumePointer = inData;
    float volume = *volumePointer;
//    NSLog(@"wonderMovieVolumeListenerCallback %d, %f", (unsigned int)inID, volume);
    [bself performSelectorOnMainThread:@selector(tryToSetVolume:) withObject:@(volume) waitUntilDone:NO];
}

@implementation WonderFullscreenControlView
@synthesize delegate;
@synthesize controlState;
@synthesize liveCastState = _liveCastState;
@synthesize resolutions = _resolutions;
@synthesize selectedResolutionIndex = _selectedResolutionIndex;
@synthesize alertCopyrightInsteadOfDownload = _alertCopyrightInsteadOfDownload;
@synthesize tvDramaManager = _tvDramaManager;
@synthesize brightness = _brightness;
@synthesize volume = _volume;
@synthesize historyOperator;
@synthesize bookmarkOperator;

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
    //NSLog(@"dealloc WonderMovieFullScreenControlView");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dimControl) object:nil];
    
    // 1. remove timer resource, actually it should be released already
    [self removeTimer];
}

#pragma mark UIView Layout
- (void)setupView
{
    BOOL hasBlurSupport = NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1;
    
    CGFloat buttonWidth = 60;
    CGFloat buttonMyVideoWidth = 60 * 1.5;
    CGFloat headerBarRightPadding = 0;
    CGFloat buttonFontSize = 13;
    UIFont *buttonFont = [UIFont systemFontOfSize:buttonFontSize];
    CGFloat statusBarHeight = 20;
    UIImage *highlightedImage = [UIImage imageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0.15]];
    
    NSMutableArray *lockedViews = [NSMutableArray array];
    
    self.backgroundColor = [UIColor clearColor];
    
    UIView *errorView = [[UIView alloc] initWithFrame:self.bounds];
    errorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    errorView.backgroundColor = [UIColor blackColor];
    self.errorView = errorView;
    errorView.hidden = YES;
    [self addSubview:errorView];
    
    // all controls add to contentView
    UIView *contentView = [[UIView alloc] initWithFrame:self.bounds];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.backgroundColor = [UIColor clearColor];
    self.contentView = contentView;
    [self addSubview:self.contentView];
    
    CGFloat bottomBarHeight = 49;
    CGFloat progressLineHeight = 2;
    CGFloat progressIndicatorHeight = 30;
    CGFloat progressIndicatorCenterY = kProgressIndicatorLeading + progressIndicatorHeight / 2;
    CGFloat bottomBarContainerHeight = bottomBarHeight + progressLineHeight / 2 + progressIndicatorCenterY;
    CGFloat headerBarHeight = 44;

    // Setup bottomBar
    
    UIView *bottomBarContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.height - bottomBarContainerHeight, self.width, bottomBarContainerHeight)];
    bottomBarContainer.backgroundColor = [UIColor clearColor];
    bottomBarContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [contentView addSubview:bottomBarContainer];
    self.bottomBarContainer = bottomBarContainer;
    self.bottomBarContainer.userInteractionEnabled = NO;

    UIView *bottomBarBg = nil;
    if (hasBlurSupport) {
        UIToolbar *bottomBarWithBlur = [[UIToolbar alloc] initWithFrame:CGRectMake(0, bottomBarContainerHeight - bottomBarHeight, self.width, bottomBarHeight)];
        bottomBarWithBlur.barStyle = UIBarStyleBlack;
        bottomBarWithBlur.translucent = YES;
//        bottomBarWithBlur.barTintColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        bottomBarBg = bottomBarWithBlur;
    }
    else {
        bottomBarBg = [[UIView alloc] initWithFrame:CGRectMake(0, bottomBarContainerHeight - bottomBarHeight, self.width, bottomBarHeight)];
        bottomBarBg.backgroundColor = [UIColor colorWithPatternImage:QQVideoPlayerImage(@"toolbar")];
    }
    bottomBarBg.autoresizingMask = UIViewAutoresizingFlexibleWidth;

#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_HIDE_BOTTOMBAR_UNTIL_STARTED
    self.bottomBarContainer.top = self.bottom; // hide bottom bar until movie started
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_HIDE_BOTTOMBAR_UNTIL_STARTED

    [bottomBarContainer addSubview:bottomBarBg];
    
    self.bottomView = [[WonderFullScreenBottomView alloc] initWithFrame:bottomBarBg.frame];
    self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.bottomView.actionButton addTarget:self action:@selector(onClickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.nextButton addTarget:self action:@selector(onClickNext:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.downloadButton addTarget:self action:@selector(onClickDownload:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.bookmarkButton addTarget:self action:@selector(onClickBookmark:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView.resolutionButton addTarget:self action:@selector(onClickResolution:) forControlEvents:UIControlEventTouchUpInside];
    [bottomBarContainer addSubview:self.bottomView];
    
    WonderProgressView *progressView = [[WonderProgressView alloc] initWithFrame:CGRectMake(0, 0, self.width, progressIndicatorHeight)];
    self.progressView = progressView;
    [bottomBarContainer addSubview:progressView];
    
    self.progressView.delegate = self;
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.progressView.userInteractionEnabled = NO;
    
    
    // Setup headerBar
    UIView *headerBar;
    if (hasBlurSupport) {
        UIToolbar *headerBarWithBlur = [[UIToolbar alloc] initWithFrame:CGRectMake(0, statusBarHeight, self.width, headerBarHeight)];
        headerBarWithBlur.barStyle = UIBarStyleBlack;
        headerBarWithBlur.translucent = YES;
//        headerBarWithBlur.barTintColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        headerBar = headerBarWithBlur;
    }
    else {
        headerBar = [[UIView alloc] initWithFrame:CGRectMake(0, statusBarHeight, self.width, headerBarHeight)];
        headerBar.backgroundColor = [UIColor colorWithPatternImage:QQVideoPlayerImage(@"headerbar")];
    }
    
    self.headerBar = headerBar;
    self.headerBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [contentView addSubview:self.headerBar];
    
    UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, -statusBarHeight, self.width, statusBarHeight)];
    statusBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    statusBarView.backgroundColor = [UIColor colorWithPatternImage:QQVideoPlayerImage(@"statusbar_bg")];
    [self.headerBar addSubview:statusBarView];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:QQVideoPlayerImage(@"back") forState:UIControlStateNormal];
    backButton.frame = CGRectMake(2, 0, 53, headerBarHeight);
    backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [backButton addTarget:self action:@selector(onClickBack:) forControlEvents:UIControlEventTouchUpInside];
    [backButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self.headerBar addSubview:backButton];
    
    UIImageView *separatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"headerbar_separator")];
    separatorView.center = CGPointMake(backButton.right, self.headerBar.height / 2);
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self.headerBar addSubview:separatorView];
    [lockedViews addObject:separatorView];
    
    
    UILabel *menuLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.headerBar.width - headerBarRightPadding - buttonWidth, 0, buttonWidth, headerBarHeight)];
    menuLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    menuLabel.backgroundColor = [UIColor clearColor];
    menuLabel.textColor = [UIColor whiteColor];
    menuLabel.textAlignment = UITextAlignmentCenter;
    menuLabel.font = buttonFont;
    menuLabel.text = NSLocalizedString(@"菜单", nil);
    [self.headerBar addSubview:menuLabel];
    CGRect btnRect = menuLabel.frame;
    
    self.menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.menuButton.frame = CGRectMake(self.headerBar.width - headerBarRightPadding - buttonWidth, 0, buttonWidth + headerBarRightPadding, headerBarHeight);
    self.menuButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.menuButton.titleLabel.font = buttonFont;
    [self.menuButton addTarget:self action:@selector(onClickMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self.menuButton setBackgroundImage:highlightedImage forState:UIControlStateSelected];
    [self.headerBar addSubview:self.menuButton];
    
    self.tvDramaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tvDramaButton.frame = CGRectOffset(btnRect, -buttonWidth+1, 0);
    self.tvDramaButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.tvDramaButton setTitle:NSLocalizedString(@"剧集", nil) forState:UIControlStateNormal];
    self.tvDramaButton.titleLabel.font = buttonFont;
    [self.tvDramaButton addTarget:self action:@selector(onClickTVDrama:) forControlEvents:UIControlEventTouchUpInside];
    [self.tvDramaButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self.headerBar addSubview:self.tvDramaButton];
    btnRect = self.tvDramaButton.frame;
    
    self.myVideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    btnRect = CGRectMake(btnRect.origin.x - buttonMyVideoWidth + 1, btnRect.origin.y, buttonMyVideoWidth, btnRect.size.height);
    self.myVideoButton.frame = btnRect;
    self.myVideoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.myVideoButton setTitle:NSLocalizedString(@"我的视频", nil) forState:UIControlStateNormal];
    self.myVideoButton.titleLabel.font = buttonFont;
    [self.myVideoButton addTarget:self action:@selector(onClickMyVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.myVideoButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self.headerBar addSubview:self.myVideoButton];
    btnRect = self.myVideoButton.frame;
    
    separatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"headerbar_separator")];
    separatorView.center = CGPointMake(self.tvDramaButton.right, self.headerBar.height / 2);
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    separatorView.tag = kWonderMovieTagSeparatorAfterTVDrama;
    [self.headerBar addSubview:separatorView];
    
    separatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"headerbar_separator")];
    separatorView.center = CGPointMake(self.myVideoButton.right, self.headerBar.height / 2);
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    separatorView.tag = kWonderMovieTagSeparatorAfterMyVideo;
    [self.headerBar addSubview:separatorView];

    separatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"headerbar_separator")];
    separatorView.center = CGPointMake(self.myVideoButton.left, self.headerBar.height / 2);
    separatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    separatorView.tag = kWonderMovieTagSeparatorBeforeMyVideo;
    [self.headerBar addSubview:separatorView];
    
    if (!_downloadEnabled) {
        separatorView.hidden = YES;
        self.bottomView.downloadButton.enabled = NO;
    }
    else {
        separatorView.hidden = NO;
        self.bottomView.downloadButton.enabled = YES;
    }
    
    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(backButton.right + 1 + 9, 0, 100, headerBarHeight)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.textColor = QQColor(videoplayer_title_color);
    titleLabel.font = [UIFont systemFontOfSize:13];
    titleLabel.text = @"";
    [self.headerBar addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:self.titleLabel.frame];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    subtitleLabel.textColor = QQColor(videoplayer_subtitle_color);
    subtitleLabel.font = [UIFont systemFontOfSize:11];
    subtitleLabel.text = @"";
    [self.headerBar addSubview:subtitleLabel];
    self.subtitleLabel = subtitleLabel;
    
    
    [self showResolutionButton:NO];
    
    // for debug
//    self.resolutions = @[@"高清", @"流畅", @"标清"];
//    [self rebuildResolutionsView];
//    [self updateResolutions];

    [lockedViews addObject:self.headerBar];
    [lockedViews addObject:self.bottomBarContainer];
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
    [self addSubview:[[MPVolumeView alloc] initWithFrame:CGRectMake(-10000, -10000, 0, 0)]];
#endif // MTT_TWEAK_WONDER_MOVIE_HIDE_SYSTEM_VOLUME_VIEW
    
    WonderInfoView *infoView = [[WonderInfoView alloc] initWithFrame:[self suggestedInfoViewFrame]];
    infoView.backgroundColor = [UIColor clearColor];
    infoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.infoView = infoView;
    [self addSubview:infoView];
    [self installGestureHandlers];
    
    [self showDramaButton:NO animated:NO];
    [self showNextButton:NO animated:NO];
    self.bottomView.downloadButton.enabled = NO;
    self.bottomView.actionButton.enabled = NO;
    self.progressView.enabled = NO;
    self.bottomView.nextButton.enabled = NO;
    
    [self.bottomView layoutIfNeeded];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    // two line layout
    CGFloat headerBarHeight = self.headerBar.height;
    CGFloat maxTitleWidth = self.headerBar.width / 2 - self.titleLabel.left; //self.downloadButton.left - self.titleLabel.left - gapWidth;
    if (self.subtitleLabel.text.length == 0) {
        self.titleLabel.frame = CGRectMake(self.titleLabel.left, 0, maxTitleWidth, headerBarHeight);
    }
    else {
        CGFloat titleLabelHeight = self.titleLabel.font.lineHeight;
        self.titleLabel.frame = CGRectMake(self.titleLabel.left, headerBarHeight / 2 - titleLabelHeight, maxTitleWidth, titleLabelHeight);
        self.subtitleLabel.frame = CGRectMake(self.titleLabel.left, self.titleLabel.bottom, maxTitleWidth, headerBarHeight - self.titleLabel.bottom);
        [self.subtitleLabel sizeToFit];
    }

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
    
    UITapGestureRecognizer *doubleTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTapOverlayView:)];
    doubleTapGR.delegate = self;
    doubleTapGR.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTapGR];
    
    [singleTapGR requireGestureRecognizerToFail:doubleTapGR];
    
    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanOverlayView:)];
    self.panGestureRecognizer = panGR;
    [self addGestureRecognizer:self.panGestureRecognizer];
}

- (void)setInfoView:(WonderInfoView *)infoView
{
    if (_infoView != infoView) {
        [_infoView.replayButton removeTarget:self action:@selector(onClickReplay:) forControlEvents:UIControlEventTouchUpInside];
        [_infoView.centerPlayButton removeTarget:self action:@selector(onClickPlay:) forControlEvents:UIControlEventTouchUpInside];
        [_infoView.openSourceButton removeTarget:self action:@selector(onClickHandleError:) forControlEvents:UIControlEventTouchUpInside];
        _infoView = infoView;
        [_infoView.replayButton addTarget:self action:@selector(onClickReplay:) forControlEvents:UIControlEventTouchUpInside];
        [_infoView.centerPlayButton addTarget:self action:@selector(onClickPlay:) forControlEvents:UIControlEventTouchUpInside];
        [_infoView.openSourceButton addTarget:self action:@selector(onClickHandleError:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (CGRect)suggestedInfoViewFrame
{
    return CGRectMake(0, self.headerBar.bottom, self.width, self.height - self.headerBar.bottom - self.bottomView.height);
}

- (void)setLiveCastState:(LiveCastState)liveCastState
{
    _liveCastState = liveCastState;
    self.progressView.userInteractionEnabled = (liveCastState == LiveCastStateNo);
    
    if (liveCastState == LiveCastStateYes) {
        self.bottomView.durationLabel.text = @"直播";
        [self.bottomView setNeedsLayout];
    }
    if (_hasStarted) {
        self.progressView.enabled = (liveCastState == LiveCastStateNo);
        self.bottomView.nextButton.enabled = (liveCastState == LiveCastStateNo);
    }
    
    [self updateDownloadState];
}

- (void)updateDownloadState
{
    // only update download button enable state when liveCast is checked
    if (_liveCastState != LiveCastStateNotCheckYet) {
        self.bottomView.downloadButton.enabled = _downloadEnabled;
        [self.bottomView setNeedsLayout];
    }
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
        UIImage *highlightedImage = [UIImage imageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0.15]];
        CGFloat menuHeight = self.crossScreenEnabled ? menuButtonHeight * 2 + menuSeparatorHeight : menuButtonHeight * 1;
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
        
        ////// Lock //////
        UIButton *lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
        lockButton.frame = CGRectMake(0, topOffset, menuWidth, menuButtonHeight);
        lockButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        lockButton.titleLabel.font = buttonFont;
        [lockButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
        [lockButton addTarget:self action:@selector(onClickLock:) forControlEvents:UIControlEventTouchUpInside];
        [popupMenu addSubview:lockButton];
        
        CGFloat delta = 16;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, topOffset, menuWidth - delta, menuButtonHeight)];
        label.text = NSLocalizedString(@"锁屏", nil);
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.textAlignment = UITextAlignmentRight;
        label.font = buttonFont;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        [popupMenu addSubview:label];
        ////// Lock //////
        
        UIButton *lastButton = lockButton;
        
        if (self.crossScreenEnabled) {
            UIImageView *menuSeparatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"separator_line")];
            menuSeparatorView.frame = CGRectMake(0, lastButton.bottom, menuWidth, menuSeparatorHeight);
            [popupMenu addSubview:menuSeparatorView];
            
            UIButton *crossButton = [UIButton buttonWithType:UIButtonTypeCustom];
            crossButton.frame = CGRectOffset(lastButton.frame, 0, menuButtonHeight + menuSeparatorHeight);
            crossButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            crossButton.titleLabel.font = buttonFont;
            [crossButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
            [crossButton addTarget:self action:@selector(onClickCrossScreen:) forControlEvents:UIControlEventTouchUpInside];
            [popupMenu addSubview:crossButton];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, crossButton.top, menuWidth - delta, menuButtonHeight)];
            label.text = NSLocalizedString(@"跨屏穿越", nil);
            label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            label.textAlignment = UITextAlignmentRight;
            label.font = buttonFont;
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor whiteColor];
            [popupMenu addSubview:label];
        }
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
    CGFloat buttonWidth = 32+32, buttonHeight = 18;
    int count = self.resolutions.count;
    count = MAX(count, 0);
    
    if (_resolutionsView) {
        [_resolutionsView removeFromSuperview];
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
    
    CGFloat x = 0;//17;
    for (int i = 0; i < count; ++i) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat y = i * (menuButtonHeight + menuSeparatorHeight);
        
        button.frame = CGRectMake(x, y + 12 , buttonWidth, buttonHeight);
        button.tag = kWonderMovieResolutionButtonTagBase + i;
        button.titleLabel.font = [UIFont systemFontOfSize:11];
        [button setImage:QQVideoPlayerImage(@"ok") forState:UIControlStateNormal];
//        [button setBackgroundImage:QQVideoPlayerImage(@"resolution_button_normal") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(onClickResolutionItem:) forControlEvents:UIControlEventTouchUpInside];
        [popupMenu addSubview:button];
        
        UIImageView *menuSeparatorView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"separator_line")];
        menuSeparatorView.frame = CGRectMake(0, y + menuButtonHeight, menuWidth, menuSeparatorHeight);
        [popupMenu addSubview:menuSeparatorView];
    }
    
    popupMenu.hidden = YES;
}

- (void)updateResolutions
{
    for (int i = 0; i < self.resolutions.count; ++i) {
        int tag = kWonderMovieResolutionButtonTagBase + i;
        UIButton *button = (UIButton *)[_resolutionsView viewWithTag:tag];
        [button setTitle:self.resolutions[i] forState:UIControlStateNormal];
        if (i == self.selectedResolutionIndex) {
            button.imageView.alpha = 1;
        }
        else {
            button.imageView.alpha = 0;
        }
    }
    if (self.resolutions.count > 0 && self.selectedResolutionIndex >= 0 && self.selectedResolutionIndex < self.resolutions.count) {
        [self.bottomView.resolutionButton setTitle:self.resolutions[self.selectedResolutionIndex] forState:UIControlStateNormal];
    }
}

- (void)setResolutions:(NSArray *)resolutions
{
    if (_resolutions != resolutions) {
        
        _resolutions = [resolutions copy];
        _resolutionsChanged = YES;
        self.tvDramaManager.clarityCount = _resolutions.count;
        [self setNeedsLayout];
        [self.bottomView setNeedsLayout];
    }
}

- (void)showResolutionButton:(BOOL)show
{
//    CGFloat resolutionButtonWidth = 32 + 20 * 2, resolutionButtonPadding = 25 - 20;
//    CGFloat duration = 0.2f;
//    if (show && self.resolutionButton.hidden) {
//        // show
//        self.resolutionButton.hidden = NO;
//        [UIView animateWithDuration:duration animations:^{
//            self.bottomView.downloadButton.right = self.resolutionButton.left;
//        }];
//    }
//    else if (!show && !self.resolutionButton.hidden) {
//        // hide
//        self.resolutionButton.hidden = YES;
//        [UIView animateWithDuration:duration animations:^{
//            self.bottomView.downloadButton.right = self.resolutionButton.right;
//        }];
//    }
    self.bottomView.resolutionButton.hidden = !show;
    [self.bottomView setNeedsLayout];
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
        _lockButton = lockButton;
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


#pragma mark Error View
- (void)showError:(BOOL)show
{
    self.errorView.hidden = !show;
    [self.infoView showError:show];
}


#pragma mark Public
- (void)afterStateMachine
{
    // Update States
    [self updateStates];
    
    
    if (!_hasStarted && self.controlState == MovieControlStatePlaying) {
        [self onPlayingStarted];
    }
}

- (void)onPlayingStarted
{
    _hasStarted = YES; // start to play now, should show bottom bar
    self.bottomView.actionButton.enabled = YES;
    self.progressView.enabled = (_liveCastState == LiveCastStateNo);
    self.bottomView.nextButton.enabled = (_liveCastState == LiveCastStateNo);
    
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_HIDE_BOTTOMBAR_UNTIL_STARTED
    [UIView animateWithDuration:0.5f animations:^{
        self.bottomBarContainer.bottom = self.bottom;
    }];
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_HIDE_BOTTOMBAR_UNTIL_STARTED
    self.bottomBarContainer.userInteractionEnabled = YES;
    
    [self cancelPreviousAndPrepareToDimControl];
    
    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume ,
                                    wonderMovieVolumeListenerCallback,
                                    (__bridge void *)(self)
                                    );
}

#pragma mark MovieControlSource
- (void)installControlSource
{
    [self setupView];
    
    [self.bottomView addObservers];
}

- (void)uninstallControlSource
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dimControl) object:nil];
    [self removeTimer];
    
    [self.bottomView removeObservers];
    
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, wonderMovieVolumeListenerCallback, (__bridge void *)(self));
    //NSLog(@"uninstallControlSource");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dimControl) object:nil];
}

- (void)resetState
{
    [self updateDownloadState];
}

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle
{
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    [self setNeedsLayout];
}

- (NSString *)title
{
    return self.titleLabel.text;
}

- (NSString *)subtitle
{
    return self.subtitleLabel.text;
}

- (void)prepareToPlay
{
    _autoNextShown = NO;
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
        
        if (_playbackTime + 5 >= _duration && !_autoNextShown &&
            [self hasNextDrama]) {
            [self prepareToPlayNextDrama];
        }
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
    
    if ([self hasNextDrama]) {
        [self playNextDrama];
    }
}

- (void)playNext
{
    [self handleCommand:MovieControlCommandPlayNext param:nil notify:NO];
}

- (void)error:(NSString *)msg
{
    [self handleCommand:MovieControlCommandError param:msg notify:NO];
}

- (void)setPlaybackTime:(NSTimeInterval)playbackTime
{
    _playbackTime = playbackTime;
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
    
    long time1 = _playbackTime;
    int hour1 = time1 / 3600;
    int minute1 = time1 / 60 - hour1 * 60;
    int second1 = time1 % 60;
    NSString *durationText;
    if (hour == 0) {
        durationText = [NSString stringWithFormat:@"%02d:%02d", minute, second];
    }
    else {
        durationText = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
    }
    
    if (hour1 == 0) {
        self.bottomView.durationLabel.text = [NSString stringWithFormat:@"%02d:%02d / %@", minute1, second1, durationText];
    }
    else {
        self.bottomView.durationLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d / %@", hour1, minute1, second1, durationText];
    }
    [self.bottomView setNeedsLayout];
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
    self.infoView.loadingMessageLabel.text = @"";
}

- (void)showToast:(NSString *)toast
{
    [self.infoView showCommonToast:toast show:YES animated:YES];
}

- (void)startToDownload
{
    _isDownloading = YES;
}

- (void)pauseDownload
{
    _isDownloading = NO;
    [self setNeedsLayout];
}

- (void)continueDownload
{
    _isDownloading = YES;
}

- (void)finishDownload
{
    _isDownloading = NO;
    self.bottomView.downloadButton.enabled = NO;
//    [self.infoView showDownloadToast:NSLocalizedString(@"视频缓存完成，开始0流量本地播放", nil) show:YES animated:YES];
    [self setNeedsLayout];
}

- (void)setDownloadProgress:(CGFloat)progress
{
    _downloadProgress = progress;
    [self setNeedsLayout];
}

- (BOOL)isDownloading
{
    return _isDownloading;
}

- (void)setBrightness:(CGFloat)brightness
{
    _brightness = brightness;
    [self.infoView showBrightness:brightness];
}

- (void)setVolume:(CGFloat)volume
{
    _volume = volume;
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
    if ([self.delegate respondsToSelector:@selector(movieControlSourceExit:)]) {
        [self.delegate movieControlSourceExit:self];
    }
}

- (IBAction)onClickDownload:(id)sender
{
    AddStatWithKey(VideoPlayerStatKeyDownload);
    [self dismissAllPopupViews];
    if (_liveCastState == LiveCastStateYes) {
        [self.infoView showDownloadToast:NSLocalizedString(@"直播视频不支持下载", nil) show:YES animated:YES];
    }
    else {
        if (self.alertCopyrightInsteadOfDownload) {
            [self.infoView showDownloadToast:NSLocalizedString(@"由于版权问题，该网站视频暂不支持下载", nil) show:YES animated:YES];
        }
        else {
            if ([self.delegate respondsToSelector:@selector(movieControlSourceOnDownload:)]) {
                [self.delegate movieControlSourceOnDownload:self];
            }
        }
    }
    
    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickCrossScreen:(id)sender
{
    AddStatWithKey(VideoPlayerStatKeyCrossScreen);
    [self dismissAllPopupViews];
    if ([self.delegate respondsToSelector:@selector(movieControlSourceOnCrossScreen:)]) {
        [self.delegate movieControlSourceOnCrossScreen:self];
    }
    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickLock:(id)sender
{
    if (_isLocked) {
        AddStatWithKey(VideoPlayerStatKeyUnlock);
    }
    else {
        AddStatWithKey(VideoPlayerStatKeyLock);
    }
    
    _isLocked = !_isLocked;
    BOOL isLocked = _isLocked;
    self.panGestureRecognizer.enabled = !isLocked;
    [self dismissAllPopupViews];
    [UIView animateWithDuration:0.2f delay:0.3f options:UIViewAnimationOptionCurveEaseIn animations:^{
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

- (IBAction)onClickBookmark:(id)sender
{
    AddStatWithKey(VideoPlayerStatKeyBookmark);
    
    VideoGroup *videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
    if (videoGroup) {
        BOOL hasBookmarked = [self.bookmarkOperator isVideoGroupBookmarked:videoGroup];
        [self.bookmarkOperator bookmarkVideoGroup:videoGroup bookmark:!hasBookmarked inWebScene:FALSE];
        [self updateBookmarkTitle];
        
        if ([videoGroup isValidDrama]) {
            NSString * infoText = (!hasBookmarked) ? NSLocalizedString(@"已添加到我的视频追剧", nil) : NSLocalizedString(@"已取消追剧", nil);
            [self.infoView showCommonToast:infoText show:YES animated:YES];
        }
    }
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

- (IBAction)onClickHandleError:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(movieControlSourceHandleError:)]) {
        [self.delegate movieControlSourceHandleError:self];
    }
}

- (IBAction)onClickMenu:(UIButton *)sender
{
    AddStatWithKey(VideoPlayerStatKeyMenu);
    
    [self showPopupMenu:!self.menuButton.selected];
    [self cancelPreviousAndPrepareToDimControl];
}

- (void)showPopupMenu:(BOOL)show
{
    // Hide tip
    if (show) {
        [self showVerticalPanningTip:NO];
        [self showHorizontalPanningTip:NO];
    }
    
    self.menuButton.selected = show;
    BOOL isShowed = self.popupMenu.bottom > 0;
    if (isShowed == show) {
        return;
    }

    [UIView animateWithDuration:0.3f animations:^{
        if (show) {
            self.popupMenu.top = -1;
            self.popupMenu.alpha = 1;
        }
        else {
            self.popupMenu.bottom = 0;
            self.popupMenu.alpha = 0;
        }
    } completion:^(BOOL finished) {
        if (!show) {
            self.popupMenu = nil;
        }
    }];
}

- (BOOL)isPopupMenuShown
{
    return self.popupMenu.bottom > 0;
}

- (IBAction)onClickNext:(id)sender
{
    VideoGroup *videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
    if (self.tvDramaManager.curSetNum > 0 && videoGroup) {
        Video *nextVideo = [videoGroup videoAtSetNum:@(self.tvDramaManager.curSetNum + 1)];
        if (nextVideo) {
            [self dramaDidSelectSetNum:nextVideo.setNum.intValue];
            [self updateNextButtonState];
        }
        else {
            NSLog(@"Warnning: There no next video");
        }
    }
}

- (IBAction)onClickTVDrama:(id)sender
{
    AddStatWithKey(VideoPlayerStatKeyDrama);
    [self showOverlay:NO];
    [self showDramaView:YES];
    [self dismissAllPopupViews]; 
    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickMyVideo:(id)sender
{
    AddStatWithKey(VideoPlayerStatKeyMyVideo);
    [self showOverlay:YES];
    [self dismissAllPopupViews];
    
    if ([self.delegate respondsToSelector:@selector(movieControlSourceOnMyVideo:)]) {
        [self.delegate movieControlSourceOnMyVideo:self];
    }
}

- (IBAction)onClickResolution:(id)sender
{
    AddStatWithKey(VideoPlayerStatKeyClarity);
    BOOL animateToShow = self.resolutionsView.hidden;
    [self showResolutionView:animateToShow];
    [self cancelPreviousAndPrepareToDimControl];
}

- (IBAction)onClickResolutionItem:(UIButton *)sender
{
    [self showResolutionView:NO];
    [self cancelPreviousAndPrepareToDimControl];
    
    
    int resolutionIndex = [self.resolutions indexOfObject:sender.currentTitle];
    if (resolutionIndex >= 0 && resolutionIndex < self.resolutions.count) {
        self.tvDramaManager.currentClarity = resolutionIndex;
        self.selectedResolutionIndex = resolutionIndex;
        [self updateResolutions];
        
        if ([self.delegate respondsToSelector:@selector(movieControlSource:didChangeResolution:)]) {
            [self.delegate movieControlSource:self didChangeResolution:self.resolutions[resolutionIndex]];
        }
        
        [self dramaDidSelectSetNum:self.tvDramaManager.curSetNum];
    }
}

- (void)showResolutionView:(BOOL)show
{
    if (self.resolutionsView.superview != self.infoView) {
        [self.resolutionsView removeFromSuperview];
        [self.infoView addSubview:self.resolutionsView];
    }
    CGPoint pt = [self.infoView convertPoint:self.bottomView.resolutionButton.center fromView:self.bottomView.resolutionButton.superview];
    self.resolutionsView.right = pt.x + self.bottomView.resolutionButton.width / 2 - 10;
    if (show) {
        self.resolutionsView.top = self.infoView.height;
        self.resolutionsView.hidden = NO;
    }
    [UIView animateWithDuration:0.3 animations:^{
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
    if (self.controlState == MovieControlStateErrored) {
        [self showError:YES];
        _isLoading = NO;
    }
    else {
        [self showError:NO];
        
        if (self.controlState == MovieControlStateDefault ||
            self.controlState == MovieControlStatePlaying ||
            (self.controlState == MovieControlStateBuffering && !_bufferFromPaused)) {
            [self.bottomView.actionButton setImage:QQVideoPlayerImage(@"pause_normal") forState:UIControlStateNormal];
            self.infoView.centerPlayButton.hidden = YES;
            self.infoView.replayButton.hidden = YES;
            [self resetBufferTitle];
            if (self.controlState == MovieControlStatePlaying) {
                _isLoading = NO;
            }
        }
        else if (self.controlState == MovieControlStatePaused ||
                 (self.controlState == MovieControlStateBuffering && _bufferFromPaused)) {
            [self.bottomView.actionButton setImage:QQVideoPlayerImage(@"play_normal") forState:UIControlStateNormal];
            self.infoView.centerPlayButton.hidden = _isLoading;
            self.infoView.replayButton.hidden = YES;
            [self resetBufferTitle];
        }
        else if (self.controlState == MovieControlStateEnded) {
            // set replay
            [self.bottomView.actionButton setImage:QQVideoPlayerImage(@"play_normal") forState:UIControlStateNormal];
            self.infoView.replayButton.hidden = NO;
            self.infoView.centerPlayButton.hidden = YES;
            _isLoading = NO; // clear loading flag
            
            [self showOverlay:YES];
            [self showDramaView:NO];
        }
        else if (self.controlState == MovieControlStatePreparing) {
            [self updateTitleAndSubtitle];
            _isLoading = YES;
            self.infoView.centerPlayButton.hidden = _isLoading;
            self.infoView.replayButton.hidden = YES;
        }
    }
    
    if (_isLoading) { // continue to loading
        [self startLoading];
    }
    else {
        [self stopLoading];
    }
}

- (void)updateTitleAndSubtitle
{
    VideoGroup *videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
    if (videoGroup) {
        int setNum = self.tvDramaManager.curSetNum;
        if (videoGroup.showType.intValue == VideoGroupShowTypeGrid) {
            [self setBufferTitle:[NSString stringWithFormat:@"即将播放%@第%d集", videoGroup.videoName, setNum]];
            [self setTitle:[NSString stringWithFormat:@"%@ 第%d集", videoGroup.videoName, setNum]
                  subtitle:(videoGroup.src.length > 0 ? [NSString stringWithFormat:@"来源：%@", videoGroup.src] : @"")];
        }
        else if (videoGroup.showType.intValue == VideoGroupShowTypeList) {
            Video *video = [videoGroup videoAtSetNum:@(setNum)];
            [self setBufferTitle:video.brief];
            [self setTitle:video.brief
                  subtitle:(videoGroup.src.length > 0 ? [NSString stringWithFormat:@"来源：%@", videoGroup.src] : @"")];
        }
        else {
            [self setBufferTitle:videoGroup.videoName];
            [self setTitle:videoGroup.videoName
                  subtitle:(videoGroup.src.length > 0 ? [NSString stringWithFormat:@"来源：%@", videoGroup.src] : @"")];
        }
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

- (void)updateBookmarkTitle
{
    VideoGroup *videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
    BOOL hasBookmarked = [self.bookmarkOperator isVideoGroupBookmarked:videoGroup];
    self.bottomView.bookmarkButton.selected = hasBookmarked;
}

- (void)tryToSetVolume:(NSNumber *)volume
{
    [self setVolume:volume.floatValue];
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
    if ([self isPopupMenuShown]) {
        [self showPopupMenu:NO];
    }
    else {
        [self showOverlay:!animationToHide];
    }
    [self cancelPreviousAndPrepareToDimControl];
}

- (void)showOverlay:(BOOL)show
{
    BOOL animationToHide = !show;
    if ([self.delegate respondsToSelector:@selector(movieControlSource:showControlView:)]) {
        [self.delegate movieControlSource:self showControlView:!animationToHide];
    }
//    BOOL hasBlurSupport = NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1;
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
    
    CGRect progressValidRegion = CGRectMake(0, self.headerBar.bottom, gr.view.width, gr.view.height - self.headerBar.bottom - self.bottomBarContainer.height);
    
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
            
            [self dismissBrightnessTipIfShown];
            [gr setTranslation:CGPointZero inView:gr.view];
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
            [gr setTranslation:CGPointZero inView:gr.view];
        }
        
    }
    else if (fabs(offset.y) <= fabs(offset.x) * kWonderMovieHorizontalPanGestureCoordRatio &&
             CGRectContainsPoint(progressValidRegion, loc) &&
             fabs(offset.x) > kWonderMoviePanDistanceThrehold &&
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
    if (self.contentView.alpha == 1 &&
        self.controlState != MovieControlStatePaused &&
        self.controlState != MovieControlStateEnded &&
        !_isScrubbing) {
//        if ([self.delegate respondsToSelector:@selector(movieControlSource:showControlView:)]) {
//            [self.delegate movieControlSource:self showControlView:NO];
//        }
//        [UIView animateWithDuration:kWonderMovieControlDimDuration animations:^{
//            self.contentView.alpha = 0;
//        }];
//        [self dismissAllPopupViews];
        [self showOverlay:NO];
    }
}


- (UIView *)horizontalPanningTipView
{
    if (_horizontalPanningTipView == nil) {
        UIView *tipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 181, 38)];
        tipView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        tipView.backgroundColor = [UIColor clearColor];
        
        UIImageView *bgImageView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"progress_prompt_bg")];
        [tipView addSubview:bgImageView];
        
        UIImageView *circleView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"progress_prompt_circle")];
        [tipView addSubview:circleView];
        
        UIImageView *fingerView = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"progress_prompt_gesture")];
        [tipView addSubview:fingerView];
        
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
        CGFloat padding = 10;
        UIView *mainTipView = [[UIView alloc] initWithFrame:self.infoView.bounds];
        
        UIView *tipView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38, 181)];
        tipView1.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        tipView1.backgroundColor = [UIColor clearColor];
        
        UIImageView *bgImageView1 = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"brightness_prompt_bg")];
        [tipView1 addSubview:bgImageView1];
        
        UIImageView *circleView1 = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"volume_prompt_circle")];
        [tipView1 addSubview:circleView1];
        
        UIImageView *fingerView1 = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"volume_prompt_gesture")];
        [tipView1 addSubview:fingerView1];
        
        [mainTipView addSubview:tipView1];
        tipView1.center = CGPointMake(padding + tipView1.width / 2, self.infoView.height / 2);
        
        UIView *tipView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38, 181)];
        tipView2.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        tipView2.backgroundColor = [UIColor clearColor];
        
        UIImageView *bgImageView2 = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"volume_prompt_bg")];
        [tipView2 addSubview:bgImageView2];
        
        UIImageView *circleView2 = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"volume_prompt_circle")];
        [tipView2 addSubview:circleView2];
        
        UIImageView *fingerView2 = [[UIImageView alloc] initWithImage:QQVideoPlayerImage(@"volume_prompt_gesture")];
        [tipView2 addSubview:fingerView2];
        
        [mainTipView addSubview:tipView2];
        tipView2.center = CGPointMake(self.infoView.width - padding - tipView2.width / 2, self.infoView.height / 2);
        
        // add animation
        CGFloat delta = 16;
        circleView1.origin = CGPointMake(0, 27 - delta);
        fingerView1.origin = CGPointMake(0, circleView1.top - 2.5);
        circleView2.origin = CGPointMake(0, 27 - delta);
        fingerView2.origin = CGPointMake(0, circleView2.top - 2.5);

        
        [UIView animateWithDuration:1.6f delay:0 options:UIViewAnimationOptionRepeat animations:^{
            circleView1.top += delta * 2;
            fingerView1.top += delta * 2;
            circleView2.top += delta * 2;
            fingerView2.top += delta * 2;
        } completion:nil];
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
            circleView1.alpha = 0.1;
            circleView2.alpha = 0.1;
        } completion:nil];
        
        _verticalPanningTipView = mainTipView;
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
        
        view.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapDramaView:)];
        tapGR.delegate = self;
        [view addGestureRecognizer:tapGR];
        
        CGFloat width = 326;
        WonderMovieDramaView *dramaView = [[WonderMovieDramaView alloc] initWithFrame:CGRectMake(self.width - width, 0, width, self.height)];
        dramaView.tvDramaManager = self.tvDramaManager;
        dramaView.delegate = self;
        [view addSubview:dramaView];
        self.dramaView = dramaView;
        
        view.left = self.width;
    }
    
    if (self.dramaContainerView.superview != self) {
        [self addSubview:self.dramaContainerView];
    }
    if (show) {
        [self.dramaView reloadData];
        
        // Scroll to the pos of current set
        [self.dramaView scrollToThePlayingOne];
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
    if (self.tvDramaManager) {
        [self.tvDramaManager getDramaInfo:TVDramaRequestTypeCurrent completionBlock:^(BOOL success) {
            if (success) {
                [self performSelectorOnMainThread:@selector(finishLoadDramaInfo) withObject:nil waitUntilDone:NO];
            }
            else {
                [self performSelectorOnMainThread:@selector(failLoadDramaInfo) withObject:nil waitUntilDone:NO];
            }
        }];
    }
    else {
        [self failLoadDramaInfo];
    }
}

- (void)finishLoadDramaInfo
{
    VideoGroup *videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
    if ([videoGroup isValidDrama]) {
        [self showDramaButton:YES animated:YES];
    }
    else {
        [self showDramaButton:NO animated:NO];
    }
    
    [self showBookmarkButton:[videoGroup isRecognized]];
    
    [self updateNextButtonState];
    [self updateTitleAndSubtitle];
    [self updateDownloadState];
    [self visitVideo:YES];
    [self updateBookmarkTitle];
    
    if ([self.delegate respondsToSelector:@selector(movieControlSourceDramaLoadFinished:)]) {
        [self.delegate movieControlSourceDramaLoadFinished:self];
    }
}

- (void)failLoadDramaInfo
{
    [self showDramaButton:NO animated:YES];
    [self showNextButton:NO animated:YES];
    [self updateDownloadState];
    [self visitVideo:YES];
    [self updateBookmarkTitle];
    
    if ([self.delegate respondsToSelector:@selector(movieControlSourceDramaLoadFinished:)]) {
        [self.delegate movieControlSourceDramaLoadFinished:self];
    }
}

- (void)showDramaButton:(BOOL)show animated:(BOOL)animated
{
    BOOL needShow = show && self.tvDramaButton.hidden;
    BOOL needHide = !show && !self.tvDramaButton.hidden;
    
    [UIView animateWithDuration:animated ? 0.5f : 0 animations:^{
        if (needShow) {
            self.myVideoButton.right = self.tvDramaButton.left + 1;
        }
        else if (needHide) {
            self.tvDramaButton.hidden = YES;
            self.myVideoButton.right = self.menuButton.left + 1;
        }
    } completion:^(BOOL finished) {
        if (needShow) {
            self.tvDramaButton.hidden = NO;
            UIView *separatorView = [self.headerBar viewWithTag:kWonderMovieTagSeparatorAfterMyVideo];
            separatorView.hidden = NO;
            
            separatorView = [self.headerBar viewWithTag:kWonderMovieTagSeparatorBeforeMyVideo];
            separatorView.hidden = NO;
            
            [self setNeedsLayout];
        }
        else if (needHide) {
            UIView *separatorView = [self.headerBar viewWithTag:kWonderMovieTagSeparatorAfterMyVideo];
            separatorView.hidden = YES;
            
            separatorView = [self.headerBar viewWithTag:kWonderMovieTagSeparatorBeforeMyVideo];
            separatorView.hidden = YES;
            
            [self setNeedsLayout];
        }
    }];
}

- (void)showBookmarkButton:(BOOL)show
{
    self.bottomView.bookmarkButton.hidden = !show;
    [self.bottomView setNeedsLayout];
}

- (void)showNextButton:(BOOL)show animated:(BOOL)animated
{
//    BOOL needShow = show && self.nextButton.hidden;
//    BOOL needHide = !show && !self.nextButton.hidden;
//    
//    if (needShow) {
//        self.nextButton.hidden = NO;
//    }
//    else if (needHide) {
//        self.nextButton.hidden = YES;
//    }
//    
//    [UIView animateWithDuration:animated ? 0.5f : 0 animations:^{
//        if (needShow) {
//            self.nextButton.alpha = 1;
//        }
//        else if (needHide) {
//            self.nextButton.alpha = 0;
//        }
//        [self reCalcDurationLabelOffset];
//    } completion:nil];
    self.bottomView.nextButton.hidden = !show;
    [UIView animateWithDuration:animated ? 0.5f : 0 animations:^{
        [self.bottomView layoutIfNeeded];
    }];
}

- (void)updateNextButtonState
{
    [self showNextButton:[self.tvDramaManager hasNext] animated:YES];
}

- (BOOL)hasNextDrama
{
    return !self.bottomView.nextButton.hidden;
}

#pragma mark History
- (void)visitVideo:(BOOL)visit
{
    CGFloat progress = _duration == 0 ? 0 : _playbackTime / _duration;
    [self.historyOperator visitVideo:[self.tvDramaManager playingVideo] playedProgress:progress visit:visit];
}

#pragma mark UIGestureRecognizerDelegate
// Bugfix: button doesn't repsond to any click if there is UITapGestureRecognizer in superview
// http://stackoverflow.com/questions/13515539/uibutton-not-works-in-ios-5-x-everything-is-fine-in-ios-6-x
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return !([touch.view isKindOfClass:[UIControl class]]) && !(self.dramaView && [touch.view isDescendantOfView:self.dramaView]);
}

@end


@implementation WonderFullscreenControlView (ProgressView)

- (void)wonderMovieProgressViewBeginChangeProgress:(WonderProgressView *)progressView
{
//    NSLog(@"wonderMovieProgressViewBeginChangeProgress");
    if (_hasStarted) {
        [self beginScrubbing];
    }
}

- (void)wonderMovieProgressView:(WonderProgressView *)progressView didChangeProgress:(CGFloat)progress
{
//    NSLog(@"didChangeProgress %f", progress);
//    [self scrub:progress];
    [self updateInfoViewProgress:progress];
}

- (void)wonderMovieProgressViewEndChangeProgress:(WonderProgressView *)progressView;
{
//    NSLog(@"wonderMovieProgressViewEndChangeProgress");
    [self endScrubbing:progressView.progress];
    
    if ([self canShowHorizontalPanningTip]) {
        [self showHorizontalPanningTip:YES];
    }
}

@end


static NSString *kWonderMovieHorizontalPanningTipKey = @"kWonderMovieHorizontalPanningTipKey";
static NSString *kWonderMovieVerticalPanningTipKey = @"kWonderMovieVerticalPanningTipKey";
@implementation WonderFullscreenControlView (Tip)

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
//        self.verticalPanningTipView.center = CGPointMake(self.infoView.width - 20 - self.verticalPanningTipView.width / 2, self.infoView.height / 2);
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

- (void)dismissBrightnessTipIfShown
{
    [self showVerticalPanningTip:NO];
}

- (void)tryToShowVerticalPanningTip
{
    if ([self canShowVerticalPanningTip]) {
        [self showVerticalPanningTip:YES];
    }
}

#pragma mark History
- (void)addVideoHistory
{
    VideoGroup *videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
    if (videoGroup) {
        Video *video = nil;
        if ([videoGroup isValidDrama]) {
            video = [videoGroup videoAtSetNum:@(self.tvDramaManager.curSetNum)];
        }
        else {
            video = [videoGroup.videos anyObject];
        }
        if (video) {
            [self visitVideo:YES];
        }
    }
}

@end

@implementation WonderFullscreenControlView (DramaView)

- (void)wonderMovieDramaView:(WonderMovieDramaView *)dramaView didSelectSetNum:(int)setNum
{
    [self showOverlay:YES];
    [self showDramaView:NO];
    
    [self dramaDidSelectSetNum:setNum];
}

- (void)dramaDidSelectSetNum:(int)setNum
{
    [self handleCommand:MovieControlCommandPlayNext param:nil notify:YES];
    
    self.tvDramaManager.curSetNum = setNum;
    self.tvDramaManager.webURL = [[self.tvDramaManager videoGroupInCurrentThread] videoAtSetNum:@(setNum)].url;
    
    [self.tvDramaManager sniffVideoSource:^(BOOL success) {
        // make sure to invoke UI related code in main thread
        [self performBlockInMainThread:^{
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
    if ([self.delegate respondsToSelector:@selector(movieControlSource:didPlayNext:)]) {
        VideoGroup *videoGroup = [self.tvDramaManager videoGroupInCurrentThread];
        Video *video = [videoGroup videoAtSetNum:@(setNum)];
        [self.delegate movieControlSource:self didPlayNext:video.videoSrc];
    }
}

- (void)dramaDidFailToSniff
{
    [self handleCommand:MovieControlCommandError param:nil notify:YES];
}

- (void)prepareToPlayNextDrama
{
    // show overlay
    [self showOverlay:YES];
    [self showDramaView:NO];
    [self dismissAllPopupViews];
    
    // show toast
    _autoNextShown = YES;
    [self.infoView showAutoNextToast:YES animated:YES];
}

- (void)playNextDrama
{
    int curSetNum = self.tvDramaManager.curSetNum;
    [self dramaDidSelectSetNum:curSetNum+1];
}

@end

#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER
