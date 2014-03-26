//
//  WonderFullScreenBottomView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 12/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "WonderFullScreenBottomView.h"
#import "WonderMoviePlayerConstants.h"
#import "UIView+Sizes.h"
#import "UIImage+FillColor.h"

@interface WonderMovieResolutionButton : UIButton

@end

@implementation WonderFullScreenBottomView

+ (void)initialize
{
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    [[AirPlayDetector defaultDetector] startMonitoring:[UIApplication sharedApplication].keyWindow];
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupView];
    }
    return self;
}

- (void)addObservers
{
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAirPlayAvailabilityChanged) name:AirPlayAvailabilityChanged object:nil];
    //    [self onAirPlayAvailabilityChanged]; // Check it at once
    [self performSelector:@selector(onAirPlayAvailabilityChanged) withObject:nil afterDelay:0.5];
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY
}

- (void)removeObservers
{
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AirPlayAvailabilityChanged object:nil];
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY
}

- (void)setupView
{
    CGFloat buttonFontSize = 13;
    UIFont *buttonFont = [UIFont systemFontOfSize:buttonFontSize];

    CGFloat bottomBarHeight = 49;
    CGFloat durationLabelWidth = 100;
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.actionButton setImage:QQVideoPlayerImage(@"play_normal") forState:UIControlStateNormal];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:10];
    self.actionButton.frame = CGRectMake(kActionButtonLeftPadding, bottomBarHeight - kActionButtonSize, kActionButtonSize, kActionButtonSize);
    self.actionButton.showsTouchWhenHighlighted = YES;
    [self addSubview:self.actionButton];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextButton setImage:QQVideoPlayerImage(@"next_normal") forState:UIControlStateNormal];
    self.nextButton.size = self.nextButton.currentImage.size;
    self.nextButton.frame = CGRectMake(self.actionButton.right + kActionButtonRightPadding, bottomBarHeight - kNextButtonSize, kNextButtonSize, kNextButtonSize);
    [self addSubview:self.nextButton];
    self.nextButton.showsTouchWhenHighlighted = YES;
    self.nextButton.enabled = YES;
    self.nextButton.hidden = YES;
    
    UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.nextButton.right + kNextButtonRightPadding, 0, durationLabelWidth, bottomBarHeight)];
    self.durationLabel = durationLabel;
    self.durationLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    self.durationLabel.textAlignment = UITextAlignmentLeft;
    self.durationLabel.font = [UIFont systemFontOfSize:10];
    self.durationLabel.backgroundColor = [UIColor clearColor];
    self.durationLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.durationLabel.text = @"--:-- / --:--";
    [self.durationLabel sizeToFit];
    [self addSubview:self.durationLabel];
    
    UIImage *highlightedImage = [UIImage imageWithColor:[[UIColor whiteColor] colorWithAlphaComponent:0.15]];
    
    CGFloat resolutionButtonWidth = 62, resolutionButtonHeight = 18 + 20;
    
    UIButton *resolutionButton = [WonderMovieResolutionButton buttonWithType:UIButtonTypeCustom];
    resolutionButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    resolutionButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [resolutionButton setImage:QQVideoPlayerImage(@"arrow") forState:UIControlStateNormal];
    self.resolutionButton = resolutionButton;
    resolutionButton.frame = CGRectMake(self.width - resolutionButtonWidth, (bottomBarHeight - resolutionButtonHeight) / 2, resolutionButtonWidth, resolutionButtonHeight);
    [self addSubview:resolutionButton];
    self.resolutionButton.hidden = YES;
    
    self.downloadButton.backgroundColor = [UIColor redColor];
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.downloadButton.frame = CGRectMake(self.resolutionButton.left - resolutionButtonWidth, bottomBarHeight - kBottomButtonHeight, kBottomButtonWidth, kBottomButtonHeight);
    self.downloadButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.downloadButton setTitleColor:QQColor(videoplayer_downloaded_color) forState:UIControlStateDisabled];
    [self.downloadButton setImage:QQVideoPlayerImage(@"download") forState:UIControlStateNormal];
    self.downloadButton.titleLabel.font = buttonFont;
    [self.downloadButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    self.downloadButton.enabled = NO;
    [self addSubview:self.downloadButton];
    
    self.bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.bookmarkButton.frame = CGRectMake(self.downloadButton.left - kBottomButtonWidth, bottomBarHeight - kBottomButtonHeight, kBottomButtonWidth, kBottomButtonHeight);
    self.bookmarkButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.bookmarkButton setTitleColor:QQColor(videoplayer_downloaded_color) forState:UIControlStateDisabled];
    [self.bookmarkButton setImage:QQVideoPlayerImage(@"bookmark_normal") forState:UIControlStateNormal];
    [self.bookmarkButton setImage:QQVideoPlayerImage(@"bookmark_press") forState:UIControlStateSelected];
    self.bookmarkButton.titleLabel.font = buttonFont;
    [self.bookmarkButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    [self addSubview:self.bookmarkButton];
    

    self.backgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat right = self.width;
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    if (_airPlayButton) {
        _airPlayButton.right = right - 30; // fix bug 49313859 （airplay 点击位置是固定的）
        _airPlayButton.center = CGPointMake(_airPlayButton.center.x, (self.height / 2)+2);
        right = _airPlayButton.left;
        right -= 30;
    }
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY
    
    self.resolutionButton.right = right;
    if (!self.resolutionButton.hidden) {
        right = self.resolutionButton.left;
    }
    
    self.downloadButton.right = right;
    right = self.downloadButton.left;

    self.bookmarkButton.right = right;
    if (!self.bookmarkButton.hidden) {
        right = self.bookmarkButton.left;
    }
    
    [self.durationLabel sizeToFit];
    if (self.nextButton.hidden) {
        self.durationLabel.left = self.nextButton.left;
    }
    else {
        self.durationLabel.left = self.nextButton.right + kNextButtonRightPadding;
    }
    self.durationLabel.center = CGPointMake(self.durationLabel.center.x, self.height / 2);
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
        [self setNeedsLayout];
    }
    // airplay became available and no airplay button yet, just add one
    else if (_airPlayButton == nil && isAirPlayAvailable) {
        MPVolumeView *volumeView = [[MPVolumeView alloc] init];
        volumeView.origin = CGPointMake(10000, 10000);
        volumeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        //        volumeView.backgroundColor = [UIColor redColor];
        [volumeView setShowsVolumeSlider:NO];
        [volumeView sizeToFit];
        [self addSubview:volumeView];
        [self sendSubviewToBack:volumeView];
        _airPlayButton = volumeView;
//        CGFloat delta = volumeView.width + kWonderMovieAirplayLeftPadding;
        [self setNeedsLayout];
        
        for (UIView *view in volumeView.subviews) {
            if ([view isKindOfClass:[UIButton class]] && view.hidden == NO) {
                UIButton *airplayButton = (UIButton *)view;
                [airplayButton addTarget:self action:@selector(onClickAirPlay:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
    }
}

- (IBAction)onClickAirPlay:(id)sender
{
    AddStatWithKey(VideoPlayerStatKeyAirPlay);
}
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY

@end


@implementation WonderMovieResolutionButton

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat padding = 0;
    CGFloat width = self.titleLabel.width + self.imageView.width + padding;
    
    self.titleLabel.frame = CGRectMake((self.width - width) / 2, (self.height - self.titleLabel.height) / 2, self.titleLabel.width, self.titleLabel.height);
    self.imageView.frame = CGRectMake(self.titleLabel.right + padding, (self.height - self.imageView.height) / 2, self.imageView.width, self.imageView.height);
}

@end

