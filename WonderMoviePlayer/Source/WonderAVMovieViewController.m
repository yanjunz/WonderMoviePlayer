//
//  WonderAVMovieViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-16.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "WonderAVMovieViewController.h"
#import "WonderAVPlayerView.h"
#import "WonderMovieFullscreenControlView.h"
#import "UIView+Sizes.h"

// y / x
#define kWonderMovieVerticalPanGestureCoordRatio    1.732050808f
#define kWonderMovieHorizontalPanGestureCoordRatio  1.0f

#define OBSERVER_CONTEXT_NAME(prefix, property) prefix##property##_ObserverContext

#define DECLARE_OBSERVER_CONTEXT(prefix, property) \
    static void *prefix##property##_ObserverContext = &prefix##property##_ObserverContext;

#define WonderAVMovieObserverContextName(property) OBSERVER_CONTEXT_NAME(WonderAVMovieViewController, property)

DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, TimedMetadata)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, Rate)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, CurrentItem)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, PlayerItemStatus)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, PlaybackBufferEmpty)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, PlaybackLikelyToKeepUp)

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
NSString *kTimedMetadataKey	= @"currentItem.timedMetadata";

NSString *kPlaybackBufferEmpty = @"playbackBufferEmpty";
NSString *kPlaybackLikelyToKeeyUp = @"playbackLikelyToKeepUp";

@interface WonderAVMovieViewController () {
    BOOL _statusBarHiddenPrevious;        
}
@property (nonatomic, retain) UIView *controlView;
@end

@implementation WonderAVMovieViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
	// Do any additional setup after loading the view.
    if (self.playerLayerView == nil) {
        self.playerLayerView = [[[WonderAVPlayerView alloc] initWithFrame:self.view.bounds] autorelease];
        self.playerLayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:self.playerLayerView];
    }
    
    if (self.overlayView == nil) {
        self.overlayView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
        self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.overlayView.backgroundColor = [UIColor clearColor];
    }
    
    [self setupControlSource:YES];
    [self addOverlayView];
    
    // Setup tap GR
    [self.overlayView addGestureRecognizer:[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapOverlayView:)] autorelease]];
    [self.overlayView addGestureRecognizer:[[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanOverlayView:)] autorelease]];
}

/* Notifies the view controller that its view is about to be become visible. */
- (void)viewWillAppear:(BOOL)animated
{
    _statusBarHiddenPrevious = [UIApplication sharedApplication].statusBarHidden;
    [UIApplication sharedApplication].statusBarHidden = YES;
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
}

/* Notifies the view controller that its view is about to be dismissed,
 covered, or otherwise hidden from view. */
- (void)viewWillDisappear:(BOOL)animated
{
    [UIApplication sharedApplication].statusBarHidden = _statusBarHiddenPrevious;
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    /* Return YES for supported orientations. */
    return YES;
}

// for IOS 6
- (BOOL)shouldAutorotate{
    return YES;
}
-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeLeft;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playMovieStream:(NSURL *)movieURL
{
    if ([movieURL scheme]) {
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset keys "tracks", "playable".
         */
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
        
        NSArray *requestedKeys = @[kTracksKey, kPlayableKey];
        
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                [self prepareToPlayAsset:asset withKeys:requestedKeys];
            });
        }];
    }
}

#pragma mark Prepare to play asset

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
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
    if (self.playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(PlayerItemStatus)];
    
    [self.playerItem addObserver:self
                      forKeyPath:kPlaybackBufferEmpty
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(PlaybackBufferEmpty)];
    
	[self.playerItem addObserver:self
                      forKeyPath:kPlaybackLikelyToKeeyUp
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(PlaybackLikelyToKeepUp)];
    
    
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    seekToZeroBeforePlay = NO;
    
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
		
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:WonderAVMovieObserverContextName(CurrentItem)];
        
        /* A 'currentItem.timedMetadata' property observer to parse the media stream timed metadata. */
        [self.player addObserver:self
                      forKeyPath:kTimedMetadataKey
                         options:0
                         context:WonderAVMovieObserverContextName(TimedMetadata)];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
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
	/* AVPlayerItem "status" property value observer. */
	if (context == WonderAVMovieObserverContextName(PlayerItemStatus)) {
        AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        NSLog(@"status changed: %d", status);
        switch (status) {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self removePlayerTimeObserver];
                
                [self.controlSource buffer];
            }
                break;
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                self.playerLayerView.playerLayer.hidden = NO;
                
                [self.controlSource unbuffer];
            
                self.playerLayerView.playerLayer.backgroundColor = [[UIColor blackColor] CGColor];
                
                /* Set the AVPlayerLayer on the view to allow the AVPlayer object to display
                 its content. */
                [self.playerLayerView.playerLayer setPlayer:self.player];
                
                [self initScrubberTimer];
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
    /* AVPlayer "rate" property value observer. */
    else if (context == WonderAVMovieObserverContextName(Rate)) {
        
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
            
            // FIXME
        }
    }
    else if (context == WonderAVMovieObserverContextName(PlaybackBufferEmpty)) {
        NSLog(@"buffer");
        [self.controlSource buffer];
    }
    else if (context == WonderAVMovieObserverContextName(PlaybackLikelyToKeepUp)) {
        NSLog(@"unbuffer");
        [self.controlSource unbuffer];
    }
    else {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
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
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
														message:[error localizedFailureReason]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

#pragma mark Player Notifications

/* Called when the player item has played to its end time. */
- (void) playerItemDidReachEnd:(NSNotification*) aNotification
{
	/* Hide the 'Pause' button, show the 'Play' button in the slider control */
    [self.controlSource end];
    
	/* After the movie has played to its end time, seek back to time zero
     to play it again */
	seekToZeroBeforePlay = YES;
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
        WonderMovieFullscreenControlView *fullscreenControlView = [[[WonderMovieFullscreenControlView alloc] initWithFrame:self.overlayView.bounds autoPlayWhenStarted:YES nextEnabled:YES] autorelease];
        fullscreenControlView.delegate = self;
        fullscreenControlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.controlView = fullscreenControlView;
        [self.overlayView addSubview:fullscreenControlView];
        self.controlSource = fullscreenControlView;
    }
}

#pragma mark scrubber timer
- (void)initScrubberTimer
{
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
    
    timeObserver = [[self.player addPeriodicTimeObserverForInterval:CMTimeMake(interval, NSEC_PER_SEC)
                                                              queue:NULL usingBlock:^(CMTime time) {
                                                                  [self syncScrubber];
                                                              }] retain];
}

- (void)removePlayerTimeObserver
{
    if (timeObserver) {
        [self.player removeTimeObserver:timeObserver];
        [timeObserver release];
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
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration) && duration > 0) {
        double time = CMTimeGetSeconds([self.player currentTime]);
        CGFloat progress = time / duration;
        NSArray *loadedTimeRanges = self.player.currentItem.loadedTimeRanges;
        CGFloat playableDuration = 0;
        if (loadedTimeRanges.count > 0) {
            NSValue *timeRangeValue = [loadedTimeRanges lastObject];
            CMTimeRange tr = [timeRangeValue CMTimeRangeValue];
            playableDuration = CMTimeGetSeconds(tr.start) + CMTimeGetSeconds(tr.duration);
        }
        
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
    restoreAfterScrubbingRate = [self.player rate];
    [self.player setRate:0];
    
    /* Remove previous timer. */
	[self removePlayerTimeObserver];
}

- (void)endScrubbing
{
    if (!timeObserver)
	{
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration))
		{
			return;
		}
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
            CGFloat width = self.view.frame.size.width;
            if ([self.controlSource respondsToSelector:@selector(getTimeControlWidth)]) {
                width = [self.controlSource getTimeControlWidth];
            }
			double tolerance = 0.5f * duration / width;
            
			timeObserver = [[self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:
                             ^(CMTime time)
                             {
                                 [self syncScrubber];
                             }] retain];
		}
	}
    
	if (restoreAfterScrubbingRate > 0)
	{
		[self.player setRate:restoreAfterScrubbingRate];
		restoreAfterScrubbingRate = 0.f;
	}
}

- (void)scrub:(CGFloat)progress
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double time = duration * progress;
        [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    }
}

#pragma mark Player

- (CMTime)playerItemDuration
{
    AVPlayerItem *thePlayerItem = self.player.currentItem;
    if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay) {
        return self.playerItem.duration;
    }
    return kCMTimeInvalid;
}

#pragma mark MovieControlSourceDelegate
- (void)movieControlSourcePlay:(id<MovieControlSource>)source
{
    [self.player play];
}

- (void)movieControlSourcePause:(id<MovieControlSource>)source
{
    [self.player pause];
}

- (void)movieControlSourceResume:(id<MovieControlSource>)source
{
    [self.player play];
}

- (void)movieControlSourceReplay:(id<MovieControlSource>)source
{
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)movieControlSource:(id<MovieControlSource>)source setProgress:(CGFloat)progress
{
    [self scrub:progress];
}

- (void)movieControlSourceExit:(id<MovieControlSource>)source
{
    [self.player pause];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)movieControlSourceBeginChangeProgress:(id<MovieControlSource>)source
{
    [self beginScrubbing];
}

- (void)movieControlSourceEndChangeProgress:(id<MovieControlSource>)source
{
    [self endScrubbing];
}

#pragma mark Gesture handler
- (IBAction)onTapOverlayView:(UITapGestureRecognizer *)gr
{
    BOOL animationToHide = self.controlView.alpha > 0;
    [UIView animateWithDuration:0.5f animations:^{
        if (animationToHide) {
            self.controlView.alpha = 0;
        }
        else {
            self.controlView.alpha = 1;
        }
    }];
}

- (IBAction)onPanOverlayView:(UIPanGestureRecognizer *)gr
{
    CGPoint offset = [gr translationInView:gr.view];
    CGPoint loc = [gr locationInView:gr.view];
    if (fabs(offset.y) >= fabs(offset.x) * kWonderMovieVerticalPanGestureCoordRatio) {
        // vertical pan gesture, should be treated for volume or brightness
        if (loc.x < gr.view.width * 0.4) {
            // brightness
            
        }
        else if (loc.x > gr.view.width * 0.6) {
            // volume
            
        }
    }
    else if (fabs(offset.y) <= fabs(offset.x) * kWonderMovieHorizontalPanGestureCoordRatio) {
        // progress
        
    }
}

@end
