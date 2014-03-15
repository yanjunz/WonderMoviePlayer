//
//  FakeMovieInfoObtainer.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 15/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MovieInfoObtainer.h"

@interface FakeMovieInfoObtainer : NSObject<MovieInfoObtainer>
@property (nonatomic, strong) NSURL *movieURL;
- (id)initWithURL:(NSURL *)movieURL;
@end
