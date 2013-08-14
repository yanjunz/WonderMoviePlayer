//
//  WonderMovieFullscreenControlView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MovieControlSource.h"

@interface WonderMovieFullscreenControlView : UIView<MovieControlSource>
@property (nonatomic, readonly) BOOL autoPlayWhenStarted;
@property (nonatomic, readonly) BOOL nextEnabled;
- (id)initWithFrame:(CGRect)frame autoPlayWhenStarted:(BOOL)autoPlayWhenStarted nextEnabled:(BOOL)nextEnabled;
@end
