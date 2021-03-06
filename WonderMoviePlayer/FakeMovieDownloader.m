//
//  FakeMovieDownloader.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/25/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "FakeMovieDownloader.h"

@implementation FakeMovieDownloader
@synthesize movieDownloaderDelegate = _movieDownloaderDelegate;
@synthesize movieDownloaderDataSource = _movieDownloaderDataSource;
@synthesize downloadURL = _downloadURL;
@synthesize isBinded = _isBinded;

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
    self.movieDownloaderDataSource = nil;

    
    // FIXME: should not be released here
    [self.timer invalidate];
}

- (void)onTimer:(NSTimer *)timer
{
    Task *t = self.task;
        if (t.state == TaskStateDownloading) {
            CGFloat progress = t.progress + 0.05;
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

- (void)mdBindDownloadURL:(NSURL *)downloadURL delegate:(id<MovieDownloaderDelegate>)delegate dataSource:(id<MovieDownloaderDataSource>)dataSource
{
    self.downloadURL = downloadURL;
    self.movieDownloaderDelegate = delegate;
    self.movieDownloaderDataSource = dataSource;
    _isBinded = YES;
}

- (void)mdUnBind
{
    _isBinded = NO;
    self.downloadURL = nil;
    self.movieDownloaderDelegate = nil;
}

- (BOOL)mdStart
{
    self.task = [Task taskWithURL:self.downloadURL];
    [self.movieDownloaderDelegate movieDownloaderStarted:self];
    
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfURL:self.downloadURL encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"start downloading ..\n%@\n%@\n%@", self.downloadURL, content, error);
    
    return YES;
}

- (BOOL)mdPause
{
    Task *t = self.task;
    if (t) {
        t.state = TaskStatePaused;
        [self.movieDownloaderDelegate movieDownloaderPaused:self];
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)mdContinue
{
    Task *t = self.task;
    if (t) {
        t.state = TaskStateDownloading;
        [self.movieDownloaderDelegate movieDownloaderContinued:self];
        return YES;
    }
    else {
        return NO;
    }
}

- (MovieDownloadState)mdQueryDownloadState:(NSURL *)downloadURL
{
    if ([downloadURL isEqual:self.downloadURL]) {
        return (MovieDownloadState)self.task.state;
    }
    return MovieDownloadStateNotDownload;
}

@end

@implementation Task

+ (id)taskWithURL:(NSURL *)url
{
    Task *t = [[Task alloc] init];
    t.downloadURL = url;
    t.state = TaskStateDownloading;
    t.progress = 0;
    return t;
}


@end