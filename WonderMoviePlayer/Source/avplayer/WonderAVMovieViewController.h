//
//  WonderAVMovieViewController.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-16.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_AVMOVIE_PLAYER

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>
#import "BaseMoviePlayer.h"

@class AVPlayer;
@class AVPlayerItem;
@class WonderAVPlayerView;
@interface WonderAVMovieViewController : UIViewController<BaseMoviePlayer> {
    BOOL isSeeking;
	float restoreAfterScrubbingRate;
    Float64 startTime;
    
    id timeObserver;
}
@property (nonatomic, retain) NSURL *movieURL;
@property (nonatomic, retain) AVPlayer *player;
@property (nonatomic, retain) AVPlayerItem *playerItem;
@property (nonatomic, retain) IBOutlet WonderAVPlayerView *playerLayerView;
@property (nonatomic, retain) UIView *overlayView;
@property (nonatomic, retain) IBOutlet UIView *maskView;

- (void)playMovieStream:(NSURL *)movieURL;
- (void)playMovieStream:(NSURL *)movieURL fromStartTime:(Float64)time;

- (CMTime)playerItemDuration;
@end

#endif // MTT_FEATURE_WONDER_AVMOVIE_PLAYER
