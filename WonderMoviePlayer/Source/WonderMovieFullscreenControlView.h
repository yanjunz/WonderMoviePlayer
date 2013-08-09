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
@property (nonatomic, assign) BOOL autoPlayWhenStarted;
- (id)initWithFrame:(CGRect)frame autoPlayWhenStarted:(BOOL)autoPlayWhenStarted;
@end
