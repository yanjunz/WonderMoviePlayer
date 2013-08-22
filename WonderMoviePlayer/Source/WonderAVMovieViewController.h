//
//  WonderAVMovieViewController.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-16.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "MovieControlSource.h"

@class AVPlayer;
@class AVPlayerItem;
@class WonderAVPlayerView;
@interface WonderAVMovieViewController : UIViewController<MovieControlSourceDelegate> {
    BOOL isSeeking;
	BOOL seekToZeroBeforePlay;
	float restoreAfterScrubbingRate;
    
    id timeObserver;
}

@property (nonatomic, retain) AVPlayer *player;
@property (nonatomic, retain) AVPlayerItem *playerItem;
@property (nonatomic, retain) IBOutlet WonderAVPlayerView *playerLayerView;
@property (nonatomic, retain) id<MovieControlSource> controlSource;
@property (nonatomic, retain) UIView *overlayView;
- (void)playMovieStream:(NSURL *)movieURL;
@end
