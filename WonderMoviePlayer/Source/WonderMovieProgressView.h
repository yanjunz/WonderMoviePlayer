//
//  WonderMovieProgressView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_MOVIE_PLAYER

#import <UIKit/UIKit.h>

@class WonderMovieProgressView;

@protocol WonderMovieProgressViewDelegate <NSObject>

- (void)wonderMovieProgressViewBeginChangeProgress:(WonderMovieProgressView *)progressView;
- (void)wonderMovieProgressView:(WonderMovieProgressView *)progressView didChangeProgress:(CGFloat)progress;
- (void)wonderMovieProgressViewEndChangeProgress:(WonderMovieProgressView *)progressView;
@end

@interface WonderMovieProgressView : UIView
@property (nonatomic, assign) id<WonderMovieProgressViewDelegate> delegate;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat cacheProgress;
@end

#endif // MTT_FEATURE_WONDER_MOVIE_PLAYER