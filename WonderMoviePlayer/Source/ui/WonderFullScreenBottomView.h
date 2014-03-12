//
//  WonderFullScreenBottomView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 12/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef MTT_TWEAK_WONDER_MOVIE_AIRPLAY
#import "AirPlayDetector.h"
#endif // MTT_TWEAK_WONDER_MOVIE_AIRPLAY

@interface WonderFullScreenBottomView : UIView {
    MPVolumeView *_airPlayButton; // assign
}
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIButton *bookmarkButton;
@property (nonatomic, strong) UIButton *resolutionButton;

- (void)addObservers;
- (void)removeObservers;
@end
