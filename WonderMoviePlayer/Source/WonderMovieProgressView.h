//
//  WonderMovieProgressView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WonderMovieProgressView;

@protocol WonderMovieProgressViewDelegate <NSObject>

- (void)wonderMovieProgressView:(WonderMovieProgressView *)progressView didChangeProgress:(CGFloat)progress;

@end

@interface WonderMovieProgressView : UIView
@property (nonatomic, assign) id<WonderMovieProgressViewDelegate> delegate;
- (void)setProgress:(CGFloat)progress;
@end
