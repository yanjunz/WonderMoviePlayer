//
//  WonderMoiveViewController.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_MPMOVIE_PLAYER

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "BaseMoviePlayer.h"

@interface WonderMPMovieViewController : UIViewController<BaseMoviePlayer>
@property (nonatomic, retain) MPMoviePlayerController *moviePlayerController;
@property (nonatomic, retain) UIView *overlayView;
@property (nonatomic, retain) IBOutlet UIView *backgroundView;

@property (nonatomic, retain) NSURL *movieURL;

- (void)playMovieFile:(NSURL *)movieFileURL;
- (void)playMovieStream:(NSURL *)movieFileURL;
@end

#endif // MTT_FEATURE_WONDER_MPMOVIE_PLAYER