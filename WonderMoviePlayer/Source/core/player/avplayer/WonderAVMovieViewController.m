//
//  WonderAVMovieViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-16.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_AVMOVIE_PLAYER
#import "WonderMoviePlayerConstants.h"
#import "WonderAVMovieViewController.h"
#import "WonderAVPlayerView.h"
#import "WonderMovieFullscreenControlView.h"
#import "UIView+Sizes.h"
#import "VideoGroup+Additions.h"
#import "Video.h"
#import "Reachability.h"
#import "NSObject+Block.h"
#import "TVDramaManager.h"

#ifdef MTT_TWEAK_DEBUG_AVPLAYER_LEFTCYCLE
@interface WonderMovieAVPlayer : AVPlayer

@end

@implementation WonderMovieAVPlayer

- (id)initWithPlayerItem:(AVPlayerItem *)item
{
    if (self = [super initWithPlayerItem:item]) {
        AddCrashRecord(@"AVPlayer initWithPlayerItem");
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        AddCrashRecord(@"AVPlayer init");
    }
    return self;
}

- (void)dealloc
{
    AddCrashRecord(@"AVPlayer dealloc");
}

@end
#define AVPlayerClass WonderMovieAVPlayer
#else 
#define AVPlayerClass AVPlayer
#endif // MTT_TWEAK_DEBUG_AVPLAYER_LEFTCYCLE


#define OBSERVER_CONTEXT_NAME(prefix, property) prefix##property##_ObserverContext

#define DECLARE_OBSERVER_CONTEXT(prefix, property) \
    static void *prefix##property##_ObserverContext = &prefix##property##_ObserverContext;

#define WonderAVMovieObserverContextName(property) OBSERVER_CONTEXT_NAME(WonderAVMovieViewController, property)

DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, CurrentItem)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, PlayerItemStatus)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, PlaybackBufferEmpty)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, PlaybackLikelyToKeepUp)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, LoadedTimeRanges)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, Rate)

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
NSString *kRateKey          = @"rate";

NSString *kPlaybackBufferEmptyKey     = @"playbackBufferEmpty";
NSString *kPlaybackLikelyToKeeyUpKey  = @"playbackLikelyToKeepUp";
NSString *kLoadedTimeRangesKey        = @"loadedTimeRanges";

@interface WonderAVMovieViewController ()<UIAlertViewDelegate> {
    BOOL _wasPlaying;
    BOOL _isScrubbing;
    BOOL _observersHasBeenRemoved; // if the observers has been removed, need to remove observers correctly to avoid memeory leak
    BOOL _isExited;
    BOOL _hasStarted;
    
    int _seekingCount;
    
    // for fake buffer progress
    BOOL _isBuffering;
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
    CGFloat _fakeBufferProgress;
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
    BOOL _prefersStatusBarHidden;
    
    BOOL _inForeground;
}
@property (nonatomic, strong) UIView *controlView;
@property (nonatomic, assign) BOOL isEnd;
@end

@implementation WonderAVMovieViewController
@synthesize crossScreenBlock, exitBlock;
#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
@synthesize movieDownloader;
#else // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
@synthesize downloadBlock;
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER

#ifdef MTT_TWEAK_BAT_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
@synthesize batMovieDownloader;
#endif // MTT_TWEAK_BAT_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER

@synthesize myVideoBlock;
@synthesize controlSource;
@synthesize isEnd = _isEnd;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.wantsFullScreenLayout = YES; // NOTE: wantsFullScreenLayout must be set in init, sometime it will not work if it is set in viewDidLoad
        // observe parentViewController to get notification of dismiss from parent view controller
        // http://stackoverflow.com/questions/2444112/method-called-when-dismissing-a-uiviewcontroller
        [self addObserver:self forKeyPath:@"parentViewController" options:0 context:NULL];
//        NSLog(@"[WonderAVMovieViewController] init    0x%0x -->", self.hash);
        _inForeground = YES;        
    }
    return self;
}

// for debug
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

- (void)dealloc
{
//    NSLog(@"[WonderAVMovieViewController] dealloc 0x%0x <--", self.hash);
#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    [self.movieDownloader mdUnBind];
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:NO error:nil];
    
    [self removeObserver:self forKeyPath:@"parentViewController"];
    [self.controlSource uninstallControlSource];
    
    [self removeAllObservers]; // Actually all observors should be removed yet
    
    
}

- (void)removeAllObservers
{
//    NSLog(@"[WonderAVMovieViewController] removeAllObservers, 0x%x", self.hash);
    if (_observersHasBeenRemoved || self.player == nil) {
        return;
    }
//    NSLog(@"[WonderAVMovieViewController] removeAllObservers, 0x%x, %0x, %0x", self.hash, self.playerItem.hash, self.player.hash);
    _observersHasBeenRemoved = YES;
    
    [self removePlayerTimeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.playerItem removeObserver:self
                         forKeyPath:kStatusKey];
    
    [self.playerItem removeObserver:self
                         forKeyPath:kPlaybackBufferEmptyKey];
    
	[self.playerItem removeObserver:self
                         forKeyPath:kPlaybackLikelyToKeeyUpKey];
    
    [self.player removeObserver:self
                     forKeyPath:kCurrentItemKey];
    
    [self.player removeObserver:self
                     forKeyPath:kRateKey];
    
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
    [self.playerItem removeObserver:self
                     forKeyPath:kLoadedTimeRangesKey];
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [UIApplication sharedApplication].statusBarHidden = YES;
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = QQColor(videoplayer_bg_color);
    backgroundView.contentMode = UIViewContentModeBottom;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backgroundView.frame = self.view.bounds;
    [self.view addSubview:backgroundView];
    
	// Do any additional setup after loading the view.
    if (self.playerLayerView == nil) {
        WonderAVPlayerView *playerLayerView = [[WonderAVPlayerView alloc] initWithFrame:self.view.bounds];
        self.playerLayerView = playerLayerView;
        self.playerLayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    [self.view addSubview:self.playerLayerView];
    
    if (self.maskView == nil) {
        UIView *maskView = [[UIView alloc] initWithFrame:self.view.bounds];
        self.maskView = maskView;
        self.maskView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.maskView.backgroundColor = [UIColor blackColor];
    }
    self.maskView.userInteractionEnabled = NO;
    self.maskView.alpha = 0;
    [self.view addSubview:self.maskView];    
    
    if (self.overlayView == nil) {
        UIView *overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
        self.overlayView = overlayView;
        self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.overlayView.backgroundColor = [UIColor clearColor];
    }
    
    [self setupControlSource:YES];
    [self addOverlayView];
    
    // Setup notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    /* Return YES for supported orientations. */
    return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

// iOS7
- (BOOL)prefersStatusBarHidden
{
    return _prefersStatusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

// for IOS 6
- (BOOL)shouldAutorotate{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        return orientation;
    }
    else {
        return UIInterfaceOrientationLandscapeRight;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isLocalMovie
{
    return [self.movieURL isFileURL];
}

//- (void)playMovieStream:(NSURL *)movieURL
//{
//    [self playMovieStream:movieURL fromStartTime:0];
//}
//
//- (void)playMovieStream:(NSURL *)movieURL fromStartTime:(Float64)time
//{
//    if ([movieURL scheme]) {
//        startTime = time;
//        self.movieURL = movieURL;
//        _wasPlaying = YES; // start to play automatically
//        _hasStarted = NO; // clear started flag
////        return;
//        if ([self isLocalMovie] || [self checkNetworkForPreparePlay]) {
//            [self playMovieStreamAfterChecking];
//        }
//    }
//}

- (void)playMovieStream:(NSURL *)movieURL fromTime:(CGFloat)time
{
    if ([movieURL scheme]) {
        _startTime = time;
        self.movieURL = movieURL;
        _wasPlaying = YES; // start to play automatically
        _hasStarted = NO; // clear started flag
        if ([self isLocalMovie] || [self checkNetworkForPreparePlay]) {
            [self playMovieStreamAfterChecking];
        }
    }
}

- (void)playMovieStream:(NSURL *)movieURL fromProgress:(CGFloat)progress
{
    if ([movieURL scheme]) {
        _startProgress = MAX(0, MIN(progress, 1));
        self.movieURL = movieURL;
        _wasPlaying = YES; // start to play automatically
        _hasStarted = NO; // clear started flag
        if ([self isLocalMovie] || [self checkNetworkForPreparePlay]) {
            [self playMovieStreamAfterChecking];
        }
    }
}

- (void)playMovieStreamAfterChecking
{
    /*
     Create an asset for inspection of a resource referenced by a given URL.
     Load the values for the asset keys "tracks", "playable".
     */
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.movieURL options:nil];
    
    NSArray *requestedKeys = @[kTracksKey, kPlayableKey];
    
    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
            if (!_isExited) { // _isExited means play has been cancel, so skip the next play
                [self prepareToPlayAsset:asset withKeys:requestedKeys];
            }
        });
    }];
    
    // show buffer immediately
    [self buffer];
}

#pragma mark Prepare to play asset
/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
//    NSLog(@"[WonderAVMovieViewController] prepareToPlayAsset %0x", self.hash);
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                            sizeof(sessionCategory),
                            &sessionCategory);
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride);
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    OSStatus propertySetError = 0;
    UInt32 allowMixing = false;
    
    propertySetError = AudioSessionSetProperty (
                                                kAudioSessionProperty_OverrideCategoryMixWithOthers,
                                                sizeof (allowMixing),
                                                &allowMixing);
    [audioSession setActive:YES error:nil];
    
    
    /* Make sure that the value of each key has loaded successfully. */
	for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey,
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"WonderAVMoviePlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }

    [self initScrubberTimer];
    // FIXME
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem && !_observersHasBeenRemoved)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.playerItem removeObserver:self
                             forKeyPath:kStatusKey];
        
        [self.playerItem removeObserver:self
                             forKeyPath:kPlaybackBufferEmptyKey];
        
        [self.playerItem removeObserver:self
                             forKeyPath:kPlaybackLikelyToKeeyUpKey];
        
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
        [self.playerItem removeObserver:self
                             forKeyPath:kLoadedTimeRangesKey];
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */

    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(PlayerItemStatus)];
    
    [self.playerItem addObserver:self
                      forKeyPath:kPlaybackBufferEmptyKey
                         options:NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(PlaybackBufferEmpty)];
    
	[self.playerItem addObserver:self
                      forKeyPath:kPlaybackLikelyToKeeyUpKey
                         options:NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(PlaybackLikelyToKeepUp)];
    
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
    [self.playerItem addObserver:self
                      forKeyPath:kLoadedTimeRangesKey
                         options:NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(LoadedTimeRanges)];
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
    
    
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    self.isEnd = NO;
    
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[[AVPlayerClass alloc] initWithPlayerItem:self.playerItem]];
		
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(CurrentItem)];
        
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(Rate)];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur*/
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
        
        // FIXME
    }
    
    [self.controlSource prepareToPlay];
#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    [self.movieDownloader mdBindDownloadURL:self.movieURL delegate:self dataSource:self];
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    _seekingCount = 0; // actually no need but for safe
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    // get notification of dismiss from parent view controller
    // http://stackoverflow.com/questions/2444112/method-called-when-dismissing-a-uiviewcontroller
//    NSLog(@"[WonderAVMovieViewController] observe 0x%0x %@, %d", self.hash, path, self.parentViewController!=nil);
    if ([@"parentViewController" isEqualToString:path] && object == self) {
        if (!self.parentViewController) {
            _isExited = YES;
            // dismiss this viewcontroller
            [self removeAllObservers];
        }
        return;
    }
    
    
	/* AVPlayerItem "status" property value observer. */
	if (context == WonderAVMovieObserverContextName(PlayerItemStatus)) {
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
//        NSLog(@"status changed: %d", status);
        switch (status) {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self removePlayerTimeObserver];
                
                [self buffer];
            }
                break;
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                self.playerLayerView.playerLayer.hidden = NO;
                
                [self unbuffer];
            
                self.playerLayerView.playerLayer.backgroundColor = [[UIColor blackColor] CGColor];
                
                /* Set the AVPlayerLayer on the view to allow the AVPlayer object to display
                 its content. */
                [self.playerLayerView.playerLayer setPlayer:self.player];
                
                [self initScrubberTimer];
                
                if (!_hasStarted) {
                    _hasStarted = YES;
                    
                    if ([self.delegate respondsToSelector:@selector(baseMoviePlayerDidStart:)]) {
                        [self.delegate baseMoviePlayerDidStart:self];
                    }
                    
                    [self setStartPlayPoint];
                }
            }
                break;
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:thePlayerItem.error];
            }
                break;
        }
    }
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == WonderAVMovieObserverContextName(CurrentItem)) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        if (newPlayerItem == (id)[NSNull null]) {
            // FIXME
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            [self.playerLayerView.playerLayer setPlayer:self.player];
            
            /* Specifies that the player should preserve the video’s aspect ratio and
             fit the video within the layer’s bounds. */
            [self.playerLayerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            [self.player play];
        }
    }
    else if (context == WonderAVMovieObserverContextName(Rate)) {
//        NSLog(@"rate = %f, %d, %d", self.player.rate, _inForeground, _wasPlaying);
        if (!_isExited) {
            if (_isEnd) {
                [self.controlSource end];
            }
            else if (_hasStarted) {
                if (self.player.rate == 0) {
                    // Workaround:
                    if (_wasPlaying) {
                        if (_inForeground) {
                            // Force to play
                            [self.player play];
                        }
                    }
                    else {
                        [self.controlSource pause];
                    }
                }
                else {
                    [self.controlSource play];
                }
            }
        }
    }
    else if (context == WonderAVMovieObserverContextName(PlaybackBufferEmpty)) {
        if (self.player.currentItem.playbackBufferEmpty) {
//            NSLog(@"buffer");
            [self buffer];
        }
    }
    else if (context == WonderAVMovieObserverContextName(PlaybackLikelyToKeepUp)) {
        if (self.player.currentItem.playbackLikelyToKeepUp) {
//            NSLog(@"unbuffer");
            if (_hasStarted) {
                [self unbuffer];
            }
        }
    }
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
    else if (context == WonderAVMovieObserverContextName(LoadedTimeRanges)) {
        [self onLoadedTimeRangesChanged];
    }
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
    else {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
}

- (void)setStartPlayPoint
{
    if (_startProgress > 0 || _startTime > 0) {
        CMTime playerDuration = [self playerItemDuration];
        double totalTime = CMTimeGetSeconds(playerDuration);
        if (isfinite(totalTime)) {
            CGFloat newTime = _startProgress > 0 ? totalTime * _startProgress : _startTime;
            newTime = MAX(MIN(newTime, totalTime), 0);
            [self.playerItem cancelPendingSeeks];
            [self.player seekToTime:CMTimeMakeWithSeconds(newTime, 1)];
            _startProgress = 0;
            _startTime = 0;
        }
    }
}

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 **
 **  1) values of asset keys did not load successfully,
 **  2) the asset keys did load successfully, but the asset is not
 **     playable
 **  3) the item did not become ready to play.
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
//    [self removePlayerTimeObserver];
//    [self syncScrubber];
//    [self disableScrubber];
//    [self disablePlayerButtons];
    
    /* Display the error. */
    NSString *errorMsg = [NSString stringWithFormat:@"%@ [%d] URL=%@", [error localizedFailureReason], error.code, [self.movieURL absoluteString]];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
														message:errorMsg
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"确认", @"")
											  otherButtonTitles:nil];
	[alertView show];
    NSLog(@"[VideoPlayer] %@", errorMsg);
    
    [self.controlSource error:errorMsg];
}

#pragma mark Player Notifications

/* Called when the player item has played to its end time. */
- (void) playerItemDidReachEnd:(NSNotification*) aNotification
{
	/* Hide the 'Pause' button, show the 'Play' button in the slider control */
    [self syncScrubber];
    [self.controlSource end];
    
	/* After the movie has played to its end time, seek back to time zero
     to play it again */
	self.isEnd = YES;
    _wasPlaying = NO;
    [self removePlayerTimeObserver];
}

#pragma mark add Overlay
-(void)addOverlayView
{
    // add an overlay view to the window view hierarchy
    self.overlayView.frame = self.view.bounds;
    [self.view addSubview:self.overlayView];
}

- (void)setupControlSource:(BOOL)fullscreen
{
    if (fullscreen) {
#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
        BOOL downloadEnabled = !!self.movieDownloader;
#else // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
        BOOL downloadEnabled = !!self.downloadBlock;
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
        BOOL crossScreenEnabled = !!self.crossScreenBlock;
        WonderMovieFullscreenControlView *fullscreenControlView = [[WonderMovieFullscreenControlView alloc] initWithFrame:self.overlayView.bounds
                                                                                                       autoPlayWhenStarted:YES
                                                                                                           downloadEnabled:downloadEnabled
                                                                                                        crossScreenEnabled:crossScreenEnabled];
        fullscreenControlView.delegate = self;
        fullscreenControlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [fullscreenControlView installControlSource];
        
        self.controlView = fullscreenControlView;
        [self.overlayView addSubview:fullscreenControlView];
        self.controlSource = fullscreenControlView;
    }
}

#pragma mark scrubber timer
- (void)initScrubberTimer
{
    if (timeObserver || _isExited) {
        return;
    }
    
    double interval = 1.0f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        CGFloat width = self.view.frame.size.width;
        if ([self.controlSource respondsToSelector:@selector(getTimeControlWidth)]) {
            width = [self.controlSource getTimeControlWidth];
        }
        
        interval = 0.5f * duration / width;
        
        // Workaround for Bug ID 14099611: AVPlayer crashing in StitchedStreamPlayer example when playing audio
        // http://stackoverflow.com/questions/16997020/avplayer-crashing-in-stitchedstreamplayer-example-when-playing-audio
        if (interval < 1.0f) {
            interval = 1.0f;
        }
    }

    BOOL isLiveCast = !isfinite(duration); // check live cast here
    self.controlSource.liveCastState = isLiveCast ? LiveCastStateYes : LiveCastStateNo;
    
    DefineWeakSelfBeforeBlock();
    timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(interval, NSEC_PER_SEC)
                                                              queue:NULL usingBlock:^(CMTime time) {
                                                                  DefineStrongSelfInBlock(sself);
                                                                  [sself syncScrubber];
                                                              }];
//    NSLog(@"initScrubberTimer");
}

- (void)removePlayerTimeObserver
{
    if (timeObserver) {
//        NSLog(@"removePlayerTimeObserver");
        [self.player removeTimeObserver:timeObserver];
        timeObserver = nil;
    }
}

- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        [self.controlSource setPlaybackTime:0];
        return;
    }
    
    if (_seekingCount > 0) {
        // Skip when seeking
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration) && duration > 0) {
        double time = CMTimeGetSeconds([self.player currentTime]);
        CGFloat progress = time / duration;
        NSArray *loadedTimeRanges = self.player.currentItem.loadedTimeRanges;
        CGFloat playableDuration = 0;
        if (loadedTimeRanges.count > 0) {
            NSValue *timeRangeValue = [loadedTimeRanges lastObject];
            CMTimeRange tr = [timeRangeValue CMTimeRangeValue];
            playableDuration = CMTimeGetSeconds(CMTimeAdd(tr.start, tr.duration));
        }
//        NSLog(@"syncSrubber %f, %f", time, progress);
        if ([self.controlSource respondsToSelector:@selector(setDuration:)]) {
            [self.controlSource setDuration:duration];
        }
        if ([self.controlSource respondsToSelector:@selector(setPlaybackTime:)]) {
            [self.controlSource setPlaybackTime:time];
        }
        if ([self.controlSource respondsToSelector:@selector(setPlayableDuration:)]) {
            [self.controlSource setPlayableDuration:playableDuration];
        }
        if ([self.controlSource respondsToSelector:@selector(setProgress:)] && duration > 0) {
            [self.controlSource setProgress:progress];
        }
    }
}

- (void)beginScrubbing
{
    _isScrubbing = YES;
}

- (void)endScrubbing:(CGFloat)progress
{
    _isScrubbing = NO;    
    [self scrub:progress completion:nil];
}

- (void)scrub:(CGFloat)progress completion:(void (^)(BOOL finished))completion
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    _seekingCount++;
    double duration = CMTimeGetSeconds(playerDuration);
    progress = MAX(0, MIN(1, progress));
    if (isfinite(duration)) {
        double time = duration * progress;
//        NSLog(@"scrub %f, %f, %f", progress, time, duration);
        
        [self.playerItem cancelPendingSeeks];
        [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            _seekingCount --;
            if (_seekingCount < 0) {
                NSLog(@"Something wrong with seekingCount = %d", _seekingCount);
                _seekingCount = 0;
            }
            
            if (completion) {
                completion(finished);
            }
        }];
    }
}


- (void)buffer
{
    _isBuffering = YES;
    [self.controlSource buffer];
}

- (void)unbuffer
{
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
    _fakeBufferProgress = 0;
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
    
    _isBuffering = NO;
    [self.controlSource unbuffer];
}

- (void)pause
{
    _wasPlaying = NO;
    [self.player pause];
    
#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    // Pause download if reachability is in 2G/3G
    [self pauseDownloadIfWWAN];
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
}

- (void)play
{
    _wasPlaying = YES;
    [self.player play];
}

#pragma mark Fake Buffer Progress
#ifdef MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS
- (void)onLoadedTimeRangesChanged
{
    // figure out fake buffer progress
    if (_isBuffering) {
        CGFloat remainingProgress = 1 - _fakeBufferProgress;
        _fakeBufferProgress += remainingProgress * 0.1;
        CGFloat fakeProgress = _fakeBufferProgress;
        
//        NSLog(@"onLoadedTimeRangesChanged %f", fakeProgress);
        if ([self.controlSource respondsToSelector:@selector(setBufferProgress:)]) {
            [self.controlSource setBufferProgress:fakeProgress];
        }
    }
}
#endif // MTT_TWEAK_WONDER_MOVIE_PLAYER_FAKE_BUFFER_PROGRESS

#pragma mark Player

- (CMTime)playerItemDuration
{
    AVPlayerItem *thePlayerItem = self.player.currentItem;
    if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay) {
        return self.playerItem.duration;
    }
    return kCMTimeInvalid;
}

#pragma mark BaseMoviePlayer
- (UIImage *)screenShot:(CGFloat)progress size:(CGSize)size
{
    CMTime actualTime;
    NSError *error;
    
    progress = MAX(0, MIN(progress, 1));
    
    Float64 durationSeconds = CMTimeGetSeconds([self.player.currentItem.asset duration]);
    CMTime point = CMTimeMakeWithSeconds(durationSeconds * progress, 600);
    
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:self.player.currentItem.asset];
    generator.maximumSize = size;
    
    CGImageRef cgImage = [generator copyCGImageAtTime:point actualTime:&actualTime error:&error];
    if (cgImage) {
        UIImage *image = [UIImage imageWithCGImage:cgImage];
        CFRelease(cgImage);
        if (error == nil) {
            return image;
        }
    }
    return nil;
}

- (CGFloat)playedProgress
{
    CMTime playerDuration = [self playerItemDuration];
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration) && duration > 0) {
        double time = CMTimeGetSeconds([self.player currentTime]);
        CGFloat progress = time / duration;
        return progress;
    }
    else {
        return 0;
    }
}

#pragma mark MovieControlSourceDelegate
- (void)movieControlSourcePlay:(id<MovieControlSource>)source
{
    [self play];
}

- (void)movieControlSourcePause:(id<MovieControlSource>)source
{
    [self pause];
}

- (void)movieControlSourceResume:(id<MovieControlSource>)source
{
    [self play];
}

- (void)movieControlSourceReplay:(id<MovieControlSource>)source
{
    _wasPlaying = YES;
    self.isEnd = NO;
    [self.playerItem cancelPendingSeeks];
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
    [self initScrubberTimer];
}

- (void)movieControlSource:(id<MovieControlSource>)source setProgress:(CGFloat)progress
{
    if (!_isScrubbing) { // not scrubbing, this should be a tap or single setting progress action
        [self scrub:progress completion:nil];
    }
    
    if (self.isEnd) { // has been ended
        _wasPlaying = YES;
        self.isEnd = NO;
        [self.player play];
    }
}

- (void)movieControlSourceEnd:(id<MovieControlSource>)source
{
    
}

- (void)movieControlSourceExit:(id<MovieControlSource>)source
{
    // must make sure exitBlock is called one time!
    if (!_isExited) {
        _isExited = YES;
        
        if (_hasStarted) {
            _hasStarted = NO;
            if ([self.delegate respondsToSelector:@selector(baseMoviePlayerDidEnd:)]) {
                [self.delegate baseMoviePlayerDidEnd:self];
            }
        }
        
        [self.player pause];
        if([self.player respondsToSelector:@selector(cancelPendingPrerolls)]){
            [self.player cancelPendingPrerolls];
        }
        if ([self.playerItem respondsToSelector:@selector(cancelPendingSeeks)]) {
            [self.playerItem cancelPendingSeeks];
        }
        if (self.exitBlock) {
            self.exitBlock();
        }
        [self removeAllObservers];
    }
}

- (void)movieControlSourceBeginChangeProgress:(id<MovieControlSource>)source
{
    if (self.isEnd) { // if ended, simulate replay before begin scrubbing
        [self movieControlSourceReplay:source];
    }
    
    [self beginScrubbing];
}

- (void)movieControlSource:(id<MovieControlSource>)source endChangeProgress:(CGFloat)progress
{
    [self endScrubbing:progress];
}

- (void)movieControlSourceOnCrossScreen:(id<MovieControlSource>)source
{
    if (self.crossScreenBlock) {
        self.crossScreenBlock();
    }
}

- (void)movieControlSource:(id<MovieControlSource>)source increaseBrightness:(CGFloat)brightness
{
    const CGFloat kMaxMaskAlphaPercent = 0.9;
    CGFloat xAlpha = MIN(self.maskView.alpha, kMaxMaskAlphaPercent);
    CGFloat yAlpha = xAlpha / kMaxMaskAlphaPercent;
    CGFloat newYAlpha = yAlpha - brightness;
    newYAlpha = MAX(0, MIN(1, newYAlpha));
    self.maskView.alpha = newYAlpha * kMaxMaskAlphaPercent;
    if ([source respondsToSelector:@selector(setBrightness:)]) {
        [source setBrightness:1- newYAlpha];
    }
    
//    CGFloat alpha = self.maskView.alpha - brightness;
//    alpha = MAX(0, MIN(0.9, alpha));
//    self.maskView.alpha = alpha;
//    
//    if ([source respondsToSelector:@selector(setBrightness:)]) {
//        [source setBrightness:1 - alpha];
//    }
}

- (void)movieControlSource:(id<MovieControlSource>)source increaseVolume:(CGFloat)volume
{
    MPMusicPlayerController *controller = [MPMusicPlayerController applicationMusicPlayer];
    CGFloat newVolume = volume + controller.volume;
    newVolume = MIN(1, MAX(newVolume, 0));
    controller.volume = newVolume;
    
    if ([source respondsToSelector:@selector(setVolume:)]) {
        [source setVolume:newVolume];
    }
}


- (void)movieControlSourceOnDownload:(id<MovieControlSource>)source
{
#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    MovieDownloadState state = [self.movieDownloader mdQueryDownloadState:self.movieURL];
    if (state == MovieDownloadStateNotDownload || state == MovieDownloadStateFailed) {
//        [self.movieDownloader mdStart];
        if ([self checkNetworkForDownload]) {
            [self.movieDownloader mdStart];
        }
    }
    else if (state == MovieDownloadStateDownloading) {
        [self.movieDownloader mdPause];
    }
    else if (state == MovieDownloadStatePaused) {
        [self.movieDownloader mdContinue];
    }
    else if (state == MovieDownloadStateFinished) {
        // Nothing
    }
#else  // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    [self pause];
    if (self.downloadBlock) {
        self.downloadBlock();
    }
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
}

- (void)movieControlSourceOnMyVideo:(id<MovieControlSource>)source
{
    [self pause];
    if (self.myVideoBlock) {
        self.myVideoBlock();
    }
}


- (void)movieControlSourceSwitchVideoGravity:(id<MovieControlSource>)source
{
    if ([self.playerLayerView.playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        self.playerLayerView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    else {
        self.playerLayerView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    self.playerLayerView.playerLayer.bounds = self.playerLayerView.playerLayer.bounds;
}

- (void)movieControlSource:(id<MovieControlSource>)source showControlView:(BOOL)show
{
    // for iOS7
    _prefersStatusBarHidden = !show;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [UIView animateWithDuration:show ? kWonderMovieControlShowDuration : kWonderMovieControlDimDuration animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
    // for iOS6
    [[UIApplication sharedApplication] setStatusBarHidden:!show withAnimation:UIStatusBarAnimationFade];
}

// Drama
- (void)movieControlSourceDramaLoadFinished:(id<MovieControlSource>)source
{
    if ([self.delegate respondsToSelector:@selector(baseMoviePlayer:didGetVideoGroup:)]) {
        [self.delegate baseMoviePlayer:self didGetVideoGroup:[self.controlSource.tvDramaManager videoGroupInCurrentThread]];
    }
}

- (void)movieControlSourceWillPlayNext:(id<MovieControlSource>)source
{
    if (_hasStarted) {
        _hasStarted = NO;
        if ([self.delegate respondsToSelector:@selector(baseMoviePlayerDidEnd:)]) {
            [self.delegate baseMoviePlayerDidEnd:self];
        }
    }
    
    [self.player pause];
}

- (void)movieControlSource:(id<MovieControlSource>)source didPlayNext:(NSString *)videoSource
{
//    NSLog(@"play %@", videoSource);
    NSURL *url = [NSURL URLWithString:videoSource];

#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    [self.movieDownloader mdUnBind];
    [self.movieDownloader mdBindDownloadURL:url delegate:self dataSource:self];
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
    
    [self.controlSource resetState];
    [self playMovieStream:url fromProgress:0];
}

- (void)movieControlSourceFailToPlayNext:(id<MovieControlSource>)source
{
    
}

- (void)movieControlSourceHandleError:(id<MovieControlSource>)source
{
    [self movieControlSourceExit:source];
}

#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
#pragma mark MovieDownladerDelegate
- (void)movieDownloaderStarted:(id<MovieDownloader>)downloader
{
    if ([self.controlSource respondsToSelector:@selector(startToDownload)]) {
        [self.controlSource startToDownload];
    }
}

- (void)movieDownloaderPaused:(id<MovieDownloader>)downloader
{
    if ([self.controlSource respondsToSelector:@selector(pauseDownload)]) {
        [self.controlSource pauseDownload];
    }
}

- (void)movieDownloaderContinued:(id<MovieDownloader>)downloader
{
    if ([self.controlSource respondsToSelector:@selector(continueDownload)]) {
        [self.controlSource continueDownload];
    }
}

- (void)movieDownloader:(id<MovieDownloader>)downloader setProgress:(CGFloat)progress
{
    if ([self.controlSource respondsToSelector:@selector(setDownloadProgress:)]) {
        [self.controlSource setDownloadProgress:progress];
    }
}

- (void)movieDownloaderFinished:(id<MovieDownloader>)downloader
{
    [downloader mdUnBind];
    if ([self.controlSource respondsToSelector:@selector(finishDownload)]) {
        [self.controlSource finishDownload];
    }
}

#pragma mark MovieDownloaderDataSource
- (NSString *)titleForMovieDownloader:(id<MovieDownloader>)downloader
{
    VideoGroup *videoGroup = [self.controlSource.tvDramaManager videoGroupInCurrentThread];
    if ([videoGroup.videoId length] != 0 && [self.controlSource respondsToSelector:@selector(title)]) {
        return [self.controlSource title];
    }
    return nil;
}
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER

#pragma mark Notification
- (void)onEnterForeground:(NSNotification *)n
{
    _inForeground = YES;
    [self performSelector:@selector(resumePlayback) withObject:nil afterDelay:0.2f];
}

- (void)onEnterBackground:(NSNotification *)n
{
    _inForeground = NO;
    // Even though the player will pause when entering background in theory, but still pause here to make sure it is paused
    [self.player pause];
}

- (void)resumePlayback
{
    if (_wasPlaying) {
        [self.player play];
    }
}

#pragma mark Reachability Handler
#define kAlertTagForPlayInWWAN          1
#define kAlertTagForDownloadInWWAN      2
#define kAlertTagForPreparePlayInWWAN   3

- (void)onReachabilityChanged:(NSNotification *)n
{
    Reachability *reach = [n object];
    BOOL isReachableViaWiFi = [reach isReachableViaWiFi];
    BOOL isReachableViaWWAN = [reach isReachableViaWWAN];
    
    [self performBlockInMainThread:^{
        if (!isReachableViaWiFi) {
            if (isReachableViaWWAN) {
                [self.controlSource showToast:NSLocalizedString(@"切换到2G/3G网络", nil)];
                [self.player pause];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"正在使用2G/3G网络，继续播放会消耗流量。确认继续？", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) otherButtonTitles:@"继续播放", nil];
                alert.tag = kAlertTagForPlayInWWAN;
                [alert show];
            }
            else {
                // ...
                
            }
        }
        else {
            [self.controlSource showToast:NSLocalizedString(@"切换到WiFi网络", nil)];
        }
    } afterDelay:0];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertTagForPlayInWWAN) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            // play
            [self.player play];
        }
    }
    else if (alertView.tag == kAlertTagForDownloadInWWAN) {
        if (buttonIndex != alertView.cancelButtonIndex) {
#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
            [self.movieDownloader mdStart];
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
        }
    }
    else if (alertView.tag == kAlertTagForPreparePlayInWWAN) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [self playMovieStreamAfterChecking];
        }
        else {
            // Bugfix: 49119857 【视频】【2G/3G网络】竖屏播放视频时，视频自动切换到横屏，点击弹出actionsheet上的“取消”后，不能切回到竖屏
            [self performSelector:@selector(movieControlSourceExit:) withObject:self.controlSource afterDelay:1.0f];
        }
    }
}

- (BOOL)checkNetworkForDownload
{
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    if (![reach isReachableViaWiFi]) {
        if ([reach isReachableViaWWAN]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"正在使用2G/3G网络，缓存视频会消耗流量。确认继续？", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) otherButtonTitles:@"继续缓存", nil];
            alert.tag = kAlertTagForDownloadInWWAN;
            [alert show];
        }
        else {
            // ...
        }
        return NO;
    }
    else {
        return YES;
    }
}

- (BOOL)checkNetworkForPreparePlay
{
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    if (![reach isReachableViaWiFi]) {
        if ([reach isReachableViaWWAN]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"正在使用2G/3G网络，播放视频会消耗流量。确认继续？", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"取消", nil) otherButtonTitles:@"继续播放", nil];
            alert.tag = kAlertTagForPreparePlayInWWAN;
            [alert show];
        }
        else {
            // ...
        }
        return NO;
    }
    else {
        return YES;
    }
}

#ifdef MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER
- (void)pauseDownloadIfWWAN
{
    MovieDownloadState state = [self.movieDownloader mdQueryDownloadState:self.movieURL];
    if (state == MovieDownloadStateDownloading) {
        Reachability *reach = [Reachability reachabilityForInternetConnection];
        if (![reach isReachableViaWiFi]) {
            if ([reach isReachableViaWWAN]) {
                // In 2G/3G
                [self.movieDownloader mdPause];
            }
        }
    }
}
#endif // MTT_TWEAK_FULL_DOWNLOAD_ABILITY_FOR_VIDEO_PLAYER

@end
#endif // MTT_FEATURE_WONDER_AVMOVIE_PLAYER
