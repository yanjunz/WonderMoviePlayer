//
//  WonderProgressView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_MOVIE_PLAYER

#import <UIKit/UIKit.h>

@class WonderProgressView;

@protocol WonderProgressViewDelegate <NSObject>

- (void)wonderMovieProgressViewBeginChangeProgress:(WonderProgressView *)progressView;
- (void)wonderMovieProgressView:(WonderProgressView *)progressView didChangeProgress:(CGFloat)progress;
- (void)wonderMovieProgressViewEndChangeProgress:(WonderProgressView *)progressView;
@end

@interface WonderProgressView : UIView<UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<WonderProgressViewDelegate> delegate;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat cacheProgress;
@property (nonatomic, assign) BOOL enabled;
@end

#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER