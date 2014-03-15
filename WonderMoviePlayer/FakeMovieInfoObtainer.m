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
@synthesize delegate;

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
    
    [self.delegate movieInfoObtainerBeginObtainMovieInfo:self];
    [self performBlockInMainThread:^{
        if (i % 2 == 0) {
            [self.delegate movieInfoObtainer:self successObtainMovieInfoWithMovieURL:self.movieURL withProgress:0.5];
        }
        else {
            [self.delegate movieInfoObtainerFailObtainMovieInfo:self];
        }
    } afterDelay:5];
    
    i ++;
}

@end
