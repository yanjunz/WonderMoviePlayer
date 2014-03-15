//
//  MovieInfoObtainer.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 15/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MovieInfoObtainerDelegate;

@protocol MovieInfoObtainer <NSObject>
- (void)startObtainMovieInfo;
@property (nonatomic, weak) id<MovieInfoObtainerDelegate> delegate;
@end


@protocol MovieInfoObtainerDelegate <NSObject>

- (void)movieInfoObtainerBeginObtainMovieInfo:(id<MovieInfoObtainer>)movieInfoObtainer;
- (void)movieInfoObtainer:(id<MovieInfoObtainer>)movieInfoObtainer successObtainMovieInfoWithMovieURL:(NSURL *)movieURL withProgress:(CGFloat)progrss;
- (void)movieInfoObtainer:(id<MovieInfoObtainer>)movieInfoObtainer successObtainMovieInfoWithMovieURL:(NSURL *)movieURL withTime:(CGFloat)time;
- (void)movieInfoObtainerFailObtainMovieInfo:(id<MovieInfoObtainer>)movieInfoObtainer;

@end