//
//  MovieInfoObtainer.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 15/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "MovieInfoObtainer.h"

@implementation MovieInfoObtainer
@synthesize movieInfoObtainerDelegate;
@synthesize obtainedMovieURL = _obtainedMovieURL;
@synthesize obtainedProgressInfo = _obtainedProgressInfo;
@synthesize hasObtained = _hasObtained;

+ (instancetype)obtainerWithURL:(NSURL *)URL progressInfo:(MovieProgressInfo)progressInfo
{
    return [[self alloc] initWithURL:URL progressInfo:progressInfo];
}

- (id)initWithURL:(NSURL *)URL progressInfo:(MovieProgressInfo)progressInfo
{
    if (self = [super init]) {
        _obtainedMovieURL = URL;
        _obtainedProgressInfo = progressInfo;
        _hasObtained = YES;
    }
    return self;
}

- (void)startObtainMovieInfo
{
    if ([self.movieInfoObtainerDelegate respondsToSelector:@selector(movieInfoObtainerBeginObtainMovieInfo:)]) {
        [self.movieInfoObtainerDelegate movieInfoObtainerBeginObtainMovieInfo:self];
    }
    
    if (self.obtainedMovieURL) {
        if ([self.movieInfoObtainerDelegate respondsToSelector:@selector(movieInfoObtainer:successObtainMovieInfoWithMovieURL:withProgressInfo:)]) {
            [self.movieInfoObtainerDelegate movieInfoObtainer:self successObtainMovieInfoWithMovieURL:self.obtainedMovieURL withProgressInfo:self.obtainedProgressInfo];
        }
    }
    else {
        if ([self.movieInfoObtainerDelegate respondsToSelector:@selector(movieInfoObtainerFailObtainMovieInfo:)]) {
            [self.movieInfoObtainerDelegate movieInfoObtainerFailObtainMovieInfo:self];
        }
    }
}

@end
