//
//  WonderMovieFullscreenControlView+StateMachine.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/22/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "WonderMovieFullscreenControlView.h"

@interface WonderMovieFullscreenControlView (StateMachine)
- (void)handleCommand:(MovieControlCommand)cmd param:(id)param notify:(BOOL)notify;
@end
