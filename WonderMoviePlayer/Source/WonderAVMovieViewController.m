//
//  WonderAVMovieViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-16.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "WonderAVMovieViewController.h"
#import "WonderAVPlayerView.h"

#define OBSERVER_CONTEXT_NAME(prefix, property) prefix##property##_ObserverContext

#define DECLARE_OBSERVER_CONTEXT(prefix, property) \
    static void *prefix##property##_ObserverContext = &prefix##property##_ObserverContext;

#define WonderAVMovieObserverContextName(property) OBSERVER_CONTEXT_NAME(WonderAVMovieViewController, property)

static void *WonderAVMovieViewController_TimedMetadataObserverContext = &WonderAVMovieViewController_TimedMetadataObserverContext;
static void *WonderAVMovieViewController_RateObservationContext = &WonderAVMovieViewController_RateObservationContext;
static void *WonderAVMovieViewController_CurrentItemObservationContext = &WonderAVMovieViewController_CurrentItemObservationContext;
static void *WonderAVMovieViewController_PlayerItemStatusObserverContext = &WonderAVMovieViewController_PlayerItemStatusObserverContext;

DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, PlaybackBufferEmpty)
DECLARE_OBSERVER_CONTEXT(WonderAVMovieViewController, PlaybackLikelyToKeepUp)

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
NSString *kTimedMetadataKey	= @"currentItem.timedMetadata";

NSString *kPlaybackBufferEmpty = @"playbackBufferEmpty";
NSString *kPlaybackLikelyToKeeyUp = @"playbackLikelyToKeeyUp";

@interface WonderAVMovieViewController ()

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
	// Do any additional setup after loading the view.
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
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
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
                         context:WonderAVMovieViewController_PlayerItemStatusObserverContext];
    
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
                         context:WonderAVMovieViewController_CurrentItemObservationContext];
        
        /* A 'currentItem.timedMetadata' property observer to parse the media stream timed metadata. */
        [self.player addObserver:self
                      forKeyPath:kTimedMetadataKey
                         options:0
                         context:WonderAVMovieViewController_TimedMetadataObserverContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:WonderAVMovieViewController_RateObservationContext];
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
	if (context == WonderAVMovieViewController_PlayerItemStatusObserverContext) {
        
    }
    else if (context == WonderAVMovieViewController_RateObservationContext) {
        
    }
    else if (context == WonderAVMovieViewController_CurrentItemObservationContext) {
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
    }
    else if (context == WonderAVMovieObserverContextName(PlaybackLikelyToKeepUp)) {
        NSLog(@"unbuffer");
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

#pragma mark scrubber timer
- (void)initScrubberTimer
{
    double interval = .1f;
    
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

//- (BOOL)isPlaying
//{
//    
//}

@end
