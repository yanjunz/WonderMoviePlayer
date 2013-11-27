//
//  FakeMovieDownloader.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/25/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MovieDownloader.h"


@class Task;

@interface FakeMovieDownloader : NSObject<MovieDownloader>
@property (nonatomic, retain) Task *task;
@property (nonatomic, retain) NSTimer *timer;
@end

typedef enum {
    TaskStateNoDownload,
    TaskStatePaused,
    TaskStateDownloading,
    TaskStateFinished,
    TaskStateFailed,
}TaskState;

@interface Task : NSObject
@property (nonatomic, retain) NSURL *downloadURL;
@property (nonatomic) CGFloat progress;
@property (nonatomic) TaskState state;
+ (id)taskWithURL:(NSURL *)url;
@end