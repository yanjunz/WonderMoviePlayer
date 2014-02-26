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
    CGFloat _startProgress;
    CGFloat _startTime;
    
    id timeObserver;
    BOOL _isEnd;
}
@property (nonatomic, strong) NSURL *movieURL;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) IBOutlet WonderAVPlayerView *playerLayerView;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) IBOutlet UIView *maskView;

//- (void)playMovieStream:(NSURL *)movieURL;
//- (void)playMovieStream:(NSURL *)movieURL fromStartTime:(Float64)time;

- (CMTime)playerItemDuration;
- (BOOL)isLocalMovie;
@end

#endif // MTT_FEATURE_WONDER_AVMOVIE_PLAYER
