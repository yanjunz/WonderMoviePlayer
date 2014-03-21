//
//  FakeMovieInfoObtainer.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 15/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "FakeMovieInfoObtainer.h"
#import "NSObject+Block.h"

@implementation FakeMovieInfoObtainer
@synthesize hasObtained, obtainedMovieURL, obtainedProgressInfo, movieInfoObtainerDelegate;

- (id)initWithURL:(NSURL *)movieURL
{
    if (self = [super init]) {
        self.movieURL = movieURL;
    }
    return self;
}

- (void)startObtainMovieInfo
{
    static int i = 0;
    
    [self.movieInfoObtainerDelegate movieInfoObtainerBeginObtainMovieInfo:self];
    [self performBlockInMainThread:^{
        if (i % 2 == 0) {
            [self.movieInfoObtainerDelegate movieInfoObtainer:self successObtainMovieInfoWithMovieURL:self.movieURL withProgressInfo:MakeMovieProgressInfoWithProgress(0.5)];
        }
        else {
            [self.movieInfoObtainerDelegate movieInfoObtainerFailObtainMovieInfo:self];
        }
    } afterDelay:0.5];
    
    i ++;
}

@end
