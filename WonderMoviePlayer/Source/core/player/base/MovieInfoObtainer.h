//
//  MovieInfoObtainer.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 15/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    BOOL useProgress;
    union {
        CGFloat progress;
        CGFloat time;
    };
} MovieProgressInfo;

inline static MovieProgressInfo MakeMovieProgressInfoWithProgress(CGFloat progress)
{
    MovieProgressInfo progressInfo;
    progressInfo.useProgress = YES;
    progressInfo.progress = progress;
    return progressInfo;
}

inline static MovieProgressInfo MakeMovieProgressInfoWithTime(CGFloat time)
{
    MovieProgressInfo progressInfo;
    progressInfo.useProgress = NO;
    progressInfo.time = time;
    return progressInfo;
}

inline static BOOL MovieProgressInfoIsEqual(const MovieProgressInfo a, const MovieProgressInfo b)
{
    return a.useProgress == b.useProgress && a.progress == b.progress;
}

#define MovieProgressInfoZero       MakeMovieProgressInfoWithProgress(0)
#define MovieProgressInfoInvalid    MakeMovieProgressInfoWithProgress(INFINITY)

@protocol MovieInfoObtainerDelegate;

@protocol MovieInfoObtainer <NSObject>
- (void)startObtainMovieInfo;
@property (nonatomic, readonly) BOOL hasObtained;
@property (nonatomic, readonly) NSURL *obtainedMovieURL;
@property (nonatomic, readonly) MovieProgressInfo obtainedProgressInfo;
@property (nonatomic, weak) id<MovieInfoObtainerDelegate> movieInfoObtainerDelegate;
@end


@protocol MovieInfoObtainerDelegate <NSObject>

- (void)movieInfoObtainerBeginObtainMovieInfo:(id<MovieInfoObtainer>)movieInfoObtainer;
- (void)movieInfoObtainer:(id<MovieInfoObtainer>)movieInfoObtainer successObtainMovieInfoWithMovieURL:(NSURL *)movieURL withProgressInfo:(MovieProgressInfo)progrssInfo;
- (void)movieInfoObtainerFailObtainMovieInfo:(id<MovieInfoObtainer>)movieInfoObtainer;

@end

@interface MovieInfoObtainer : NSObject<MovieInfoObtainer>
+ (instancetype)obtainerWithURL:(NSURL *)URL progressInfo:(MovieProgressInfo)progressInfo;
@end