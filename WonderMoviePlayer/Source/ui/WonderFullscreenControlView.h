//
//  WonderFullscreenControlView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_MOVIE_PLAYER

#import <UIKit/UIKit.h>
#import "MovieControlSource.h"
#import "WonderInfoView.h"

@interface WonderFullscreenControlView : UIView<MovieControlSource> {
    NSTimeInterval _playbackTime;
    NSTimeInterval _playableDuration;
    NSTimeInterval _duration;
    
    // for buffer loading
    BOOL _bufferFromPaused;
    BOOL _isLoading;
    NSTimeInterval _totalBufferingSize;
    
    // scrubbing related
    BOOL _isScrubbing; // flag to ignore msg to set progress when scrubbing
    CGFloat _progressWhenStartScrubbing; // record the progress when begin to scrub
    CGFloat _accumulatedProgressBySec; // the total accumulated progress by second
    CGFloat _lastProgressToScrub;   // record the last progress to be set when scrubbing is ended
    
    BOOL _isDownloading;
    BOOL _hasStarted;
    
    BOOL _isLocked;
    

    
    BOOL _resolutionsChanged;
    
    // tip
    BOOL _wasHorizontalPanningTipShown;
    BOOL _wasVerticalPanningTipShown;
    
    // auto next toast
    BOOL _autoNextShown;
}
@property (nonatomic, assign) BOOL autoPlayWhenStarted;
@property (nonatomic, assign) BOOL crossScreenEnabled;
@property (nonatomic, strong) WonderInfoView *infoView;

- (id)initWithFrame:(CGRect)frame autoPlayWhenStarted:(BOOL)autoPlayWhenStarted crossScreenEnabled:(BOOL)crossScreenEnabled;

- (void)afterStateMachine;
@end

#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER
