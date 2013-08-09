//
//  WonderMoiveViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "WonderMoiveViewController.h"
#import "WonderMovieFullscreenControlView.h"
#import "MoviePlayerUserPrefs.h"

@interface WonderMoiveViewController ()
@property (nonatomic, retain) NSTimer *timer;
@end

@implementation WonderMoiveViewController

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
    if (self.backgroundView == nil) {
        self.backgroundView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
        self.backgroundView.backgroundColor = [UIColor blackColor];
    }
    [self setupControlSource:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (void)viewDidUnload
{
    [self deletePlayerAndNotificationObservers];
    
    [super viewDidUnload];
}

/* Notifies the view controller that its view is about to be become visible. */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /* Size the overlay view for the current orientation. */
	[self resizeOverlayWindow];
    /* Update user settings for the movie (in case they changed). */
    [self applyUserSettingsToMoviePlayer];
}

/* Notifies the view controller that its view is about to be dismissed,
 covered, or otherwise hidden from view. */
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    /* Remove the movie view from the current view hierarchy. */
	[self removeMovieViewFromViewHierarchy];
    /* Removie the overlay view. */
	[self removeOverlayView];
    /* Remove the background view. */
	[self.backgroundView removeFromSuperview];
    
    /* Delete the movie player object and remove the notification observers. */
    [self deletePlayerAndNotificationObservers];
}

/* Sent to the view controller after the user interface rotates. */
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	/* Size movie view to fit parent view. */
	CGRect viewInsetRect = CGRectInset ([self.view bounds],
										0,
										0 );
	[[[self moviePlayerController] view] setFrame:viewInsetRect];
    
    /* Size the overlay view for the current orientation. */
	[self resizeOverlayWindow];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    /* Return YES for supported orientations. */
    return YES;
}

#pragma mark add Overlay 
/* Add an overlay view on top of the movie. This view will display movie
 play states and includes a 'Close Movie' button. */
-(void)addOverlayView
{
    MPMoviePlayerController *player = [self moviePlayerController];
    
    if (!([self.overlayView isDescendantOfView:self.view])
        && ([player.view isDescendantOfView:self.view]))
    {
        // add an overlay view to the window view hierarchy
        [self.view addSubview:self.overlayView];
    }
}

/* Remove overlay view from the view hierarchy. */
-(void)removeOverlayView
{
	[self.overlayView removeFromSuperview];
}

-(void)resizeOverlayWindow
{
//	CGRect frame = self.overlayView.frame;
//	frame.origin.x = round((self.view.frame.size.width - frame.size.width) / 2.0);
//	frame.origin.y = round((self.view.frame.size.height - frame.size.height) / 2.0);
//	self.overlayView.frame = frame;
    self.overlayView.frame = self.view.bounds;
}

/* Remove the movie view from the view hierarchy. */
-(void)removeMovieViewFromViewHierarchy
{
    MPMoviePlayerController *player = [self moviePlayerController];
    
	[player.view removeFromSuperview];
}


-(void)createAndConfigurePlayerWithURL:(NSURL *)movieURL sourceType:(MPMovieSourceType)sourceType
{
    /* Create a new movie player object. */
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
    
    if (player)
    {
        /* Save the movie object. */
        self.moviePlayerController = player;
        
        /* Register the current object as an observer for the movie
         notifications. */
        [self installMovieNotificationObservers];
        
        /* Specify the URL that points to the movie file. */
        [player setContentURL:movieURL];
        
        /* If you specify the movie type before playing the movie it can result
         in faster load times. */
        [player setMovieSourceType:sourceType];
        
        /* Apply the user movie preference settings to the movie player object. */
        [self applyUserSettingsToMoviePlayer];
        
        /* Add a background view as a subview to hide our other view controls
         underneath during movie playback. */
        [self.view addSubview:self.backgroundView];
        
        CGRect viewInsetRect = CGRectInset ([self.view bounds],
                                            0,
                                            0 );
        /* Inset the movie frame in the parent view frame. */
        [[player view] setFrame:viewInsetRect];
        
        [player view].backgroundColor = [UIColor lightGrayColor];
        
        /* To present a movie in your application, incorporate the view contained
         in a movie player’s view property into your application’s view hierarchy.
         Be sure to size the frame correctly. */
        [self.view addSubview: [player view]];
    }
}

- (void)createAndPlayMovieForURL:(NSURL *)movieURL sourceType:(MPMovieSourceType)sourceType
{
    [self createAndConfigurePlayerWithURL:movieURL sourceType:sourceType];
    [self.moviePlayerController play];
}

- (void)setupControlSource:(BOOL)fullscreen
{
    if (fullscreen) {
        WonderMovieFullscreenControlView *fullscreenControlView = [[[WonderMovieFullscreenControlView alloc] initWithFrame:self.view.bounds] autorelease];
        fullscreenControlView.delegate = self;
        self.overlayView = fullscreenControlView;
        self.controlSource = fullscreenControlView;
    }
}

#pragma mark Install Movie Notifications
/* Register observers for the various movie object notifications. */
-(void)installMovieNotificationObservers
{
    MPMoviePlayerController *player = self.moviePlayerController;
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:player];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:player];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:player];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification
                                               object:player];
}

#pragma mark Remove Movie Notification Handlers

/* Remove the movie notification observers from the movie object. */
-(void)removeMovieNotificationHandlers
{
    MPMoviePlayerController *player = self.moviePlayerController;
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:player];
}

/* Delete the movie player object, and remove the movie notification observers. */
-(void)deletePlayerAndNotificationObservers
{
    [self removeMovieNotificationHandlers];
    self.moviePlayerController = nil;
}

#pragma mark Movie Settings

/* Apply user movie preference settings (these are set from the Settings: iPhone Settings->Movie Player)
 for scaling mode, control style, background color, repeat mode, application audio session, background
 image and AirPlay mode.
 */
-(void)applyUserSettingsToMoviePlayer
{
    MPMoviePlayerController *player = self.moviePlayerController;
    if (player)
    {
        player.scalingMode = [MoviePlayerUserPrefs scalingModeUserSetting];
        player.controlStyle = MPMovieControlStyleNone; //[MoviePlayerUserPrefs controlStyleUserSetting];
        player.backgroundView.backgroundColor = [MoviePlayerUserPrefs backgroundColorUserSetting];
        player.repeatMode = [MoviePlayerUserPrefs repeatModeUserSetting];
        player.useApplicationAudioSession = [MoviePlayerUserPrefs audioSessionUserSetting];
//        if ([MoviePlayerUserPrefs backgroundImageUserSetting] == YES)
//        {
//            [self.movieBackgroundImageView setFrame:[self.view bounds]];
//            [player.backgroundView addSubview:self.movieBackgroundImageView];
//        }
//        else
//        {
//            [self.movieBackgroundImageView removeFromSuperview];
//        }
        
        /* Indicate the movie player allows AirPlay movie playback. */
        player.allowsAirPlay = YES;
    }
}

#pragma mark Movie Notification Handlers

/*  Notification called when the movie finished playing. */
- (void) moviePlayBackDidFinish:(NSNotification*)notification
{
//    NSNumber *reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
//	switch ([reason integerValue])
//	{
//            /* The end of the movie was reached. */
//		case MPMovieFinishReasonPlaybackEnded:
//            /*
//             Add your code here to handle MPMovieFinishReasonPlaybackEnded.
//             */
//			break;
//            
//            /* An error was encountered during playback. */
//		case MPMovieFinishReasonPlaybackError:
//            NSLog(@"An error was encountered during playback");
//            [self performSelectorOnMainThread:@selector(displayError:) withObject:[[notification userInfo] objectForKey:@"error"]
//                                waitUntilDone:NO];
//            [self removeMovieViewFromViewHierarchy];
//            [self removeOverlayView];
//            [self.backgroundView removeFromSuperview];
//			break;
//            
//            /* The user stopped playback. */
//		case MPMovieFinishReasonUserExited:
//            [self removeMovieViewFromViewHierarchy];
//            [self removeOverlayView];
//            [self.backgroundView removeFromSuperview];
//			break;
//            
//		default:
//			break;
//	}
}

/* Handle movie load state changes. */
- (void)loadStateDidChange:(NSNotification *)notification
{
    NSLog(@"loadStateDidChange");
	MPMoviePlayerController *player = notification.object;
	MPMovieLoadState loadState = player.loadState;
//
//	/* The load state is not known at this time. */
//	if (loadState & MPMovieLoadStateUnknown)
//	{
//        [self.overlayController setLoadStateDisplayString:@"n/a"];
//        
//        [overlayController setLoadStateDisplayString:@"unknown"];
//	}
//	
//	/* The buffer has enough data that playback can begin, but it
//	 may run out of data before playback finishes. */
//	if (loadState & MPMovieLoadStatePlayable)
//	{
//        [overlayController setLoadStateDisplayString:@"playable"];
//	}
//	
	/* Enough data has been buffered for playback to continue uninterrupted. */
	if (loadState & MPMovieLoadStatePlaythroughOK)
	{
        // Add an overlay view on top of the movie view
        [self addOverlayView];
        
//        [overlayController setLoadStateDisplayString:@"playthrough ok"];
	}
//
//	/* The buffering of data has stalled. */
//	if (loadState & MPMovieLoadStateStalled)
//	{
//        [overlayController setLoadStateDisplayString:@"stalled"];
//	}
}

/* Called when the movie playback state has changed. */
- (void) moviePlayBackStateDidChange:(NSNotification*)notification
{
    NSLog(@"moviePlayBackStateDidChange");
//	MPMoviePlayerController *player = notification.object;
//    
//	/* Playback is currently stopped. */
//	if (player.playbackState == MPMoviePlaybackStateStopped)
//	{
//        [overlayController setPlaybackStateDisplayString:@"stopped"];
//	}
//	/*  Playback is currently under way. */
//	else if (player.playbackState == MPMoviePlaybackStatePlaying)
//	{
//        [overlayController setPlaybackStateDisplayString:@"playing"];
//	}
//	/* Playback is currently paused. */
//	else if (player.playbackState == MPMoviePlaybackStatePaused)
//	{
//        [overlayController setPlaybackStateDisplayString:@"paused"];
//	}
//	/* Playback is temporarily interrupted, perhaps because the buffer
//	 ran out of content. */
//	else if (player.playbackState == MPMoviePlaybackStateInterrupted)
//	{
//        [overlayController setPlaybackStateDisplayString:@"interrupted"];
//	}
}

/* Notifies observers of a change in the prepared-to-play state of an object
 conforming to the MPMediaPlayback protocol. */
- (void) mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
	// Add an overlay view on top of the movie view
    [self addOverlayView];
}


#pragma mark Public
- (void)playMovieFile:(NSURL *)movieFileURL
{
    [self stopTimer];
    [self startTimer];
    [self createAndPlayMovieForURL:movieFileURL sourceType:MPMovieSourceTypeFile];
}

- (void)playMovieStream:(NSURL *)movieFileURL
{
    [self stopTimer];
    [self startTimer];
    MPMovieSourceType movieSourceType = MPMovieSourceTypeUnknown;
    /* If we have a streaming url then specify the movie source type. */
    if ([[movieFileURL pathExtension] compare:@"m3u8" options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        movieSourceType = MPMovieSourceTypeStreaming;
    }
    [self createAndPlayMovieForURL:movieFileURL sourceType:movieSourceType];
}

#pragma mark MovieControlSourceDelegate
- (void)movieControlSourcePlay:(id<MovieControlSource>)source
{
    [self.moviePlayerController play];
}

- (void)movieControlSourcePause:(id<MovieControlSource>)source
{
    [self.moviePlayerController pause];
}

- (void)movieControlSourceResume:(id<MovieControlSource>)source
{
    [self.moviePlayerController play];
}

- (void)movieControlSourceReplay:(id<MovieControlSource>)source
{
    [self.moviePlayerController play];
}

- (void)movieControlSource:(id<MovieControlSource>)source setProgress:(CGFloat)progress
{
    self.moviePlayerController.currentPlaybackTime = progress * self.moviePlayerController.playableDuration;
    [self updateTimeLabels];
}

- (void)movieControlSourceExit:(id<MovieControlSource>)source
{
    [self.moviePlayerController stop];
}

#pragma mark Control operation
- (void)updateTimeLabels
{
    NSTimeInterval currentPlaybackTime = self.moviePlayerController.currentPlaybackTime;
    NSTimeInterval playbackDuration = self.moviePlayerController.playableDuration;
    
    if ([self.controlSource respondsToSelector:@selector(setPlaybackTime:)]) {
        [self.controlSource setPlaybackTime:currentPlaybackTime];
    }
    if ([self.controlSource respondsToSelector:@selector(setPlaybackDuration:)]) {
        [self.controlSource setPlaybackDuration:playbackDuration];
    }
    if ([self.controlSource respondsToSelector:@selector(setProgress:)]) {
        [self.controlSource setProgress:currentPlaybackTime / playbackDuration];
    }
}

- (void)startTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimeLabels) userInfo:nil repeats:YES];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

@end
