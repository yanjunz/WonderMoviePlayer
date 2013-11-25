//
//  FakeMovieDownloader.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/25/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "FakeMovieDownloader.h"

@implementation FakeMovieDownloader
@synthesize movieDownloaderDelegate;

- (id)init
{
    self = [super init];
    if (self) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)dealloc
{
    self.movieDownloaderDelegate = nil;
    [self.timer invalidate];
    self.timer = nil;
    [super dealloc];
}

- (void)onTimer:(NSTimer *)timer
{
    Task *t = self.task;
        if (t.state == TaskStateDownloading) {
            CGFloat progress = t.progress + 0.15;
            if (progress >= 1) {
                t.state = TaskStateFinished;
                t.progress = 1;
                [self.movieDownloaderDelegate movieDownloaderFinished:self];
            }
            else {
                t.progress = progress;
                [self.movieDownloaderDelegate movieDownloader:self setProgress:progress];
            }
        }
    
}

- (void)mdStartDownload:(NSURL *)downloadURL
{
    self.task = [Task taskWithURL:downloadURL];
    [self.movieDownloaderDelegate movieDownloaderStarted:self];
}

- (void)mdPause
{
    Task *t = self.task;
    if (t) {
        t.state = TaskStatePaused;
        [self.movieDownloaderDelegate movieDownloaderPaused:self];
    }
}

- (void)mdContinue
{
    Task *t = self.task;
    if (t) {
        t.state = TaskStateDownloading;
    }
}

- (BOOL)mdHasTask:(NSURL *)downloadURL
{
    return [self.task.downloadURL isEqual:downloadURL];
}

- (BOOL)mdIsDownaloading:(NSURL *)downloadURL
{
    Task *t = self.task;
    return t && t.state == TaskStateDownloading;
}

- (BOOL)mdIsFinished:(NSURL *)downloadURL
{
    Task *t = self.task;
    return t && t.state == TaskStateFinished;
}

- (BOOL)mdIsPaused:(NSURL *)downloadURL
{
    Task *t = self.task;
    return t && t.state == TaskStatePaused;
}

@end

@implementation Task

+ (id)taskWithURL:(NSURL *)url
{
    Task *t = [[[Task alloc] init] autorelease];
    t.downloadURL = url;
    t.state = TaskStateDownloading;
    t.progress = 0;
    return t;
}

- (void)dealloc
{
    self.downloadURL = nil;
    [super dealloc];
}

@end