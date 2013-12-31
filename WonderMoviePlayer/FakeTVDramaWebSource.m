//
//  FakeTVDramaWebSource.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/14/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "FakeTVDramaWebSource.h"
#import "Video.h"
#import "VideoGroup+VideoDetailSet.h"
#import "NSObject+Block.h"

@interface FakeTVDramaWebSource () <UIWebViewDelegate> {
    int _minVideoSetNum;
    int _maxVideoSetNum;
}
@property (nonatomic, retain) UIWebView *webview;
@property (nonatomic, copy) NSString *videoSrc;
@property (nonatomic, retain) NSMutableArray *urls;
@end

@implementation FakeTVDramaWebSource

- (id)init
{
    if (self = [super init]) {
        [self setupDatabase];
    }
    return self;
}

- (void)setupDatabase
{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        [VideoGroup MR_truncateAll];
        NSArray *videoGroups = [VideoGroup MR_findAll];
        if (videoGroups.count == 0) {
            VideoGroup *videoGroup = [VideoGroup MR_createEntity];
            
            NSMutableArray *urls = [NSMutableArray arrayWithArray:@[
                                                                    @"http://www.iqiyi.com/dongman/20130407/1.html",
                                                                    @"http://www.iqiyi.com/dongman/20130414/2.html",
                                                                    @"http://www.iqiyi.com/dongman/20130421/3.html",
                                                                    @"http://www.iqiyi.com/dongman/20130428/4.html",
                                                                    @"http://www.iqiyi.com/dongman/20130505/5.html",
                                                                    
                                                                    @"http://www.iqiyi.com/dongman/20130407/6.html",
                                                                    @"http://www.iqiyi.com/dongman/20130414/7.html",
                                                                    @"http://www.iqiyi.com/dongman/20130421/8.html",
                                                                    @"http://www.iqiyi.com/dongman/20130428/9.html",
                                                                    @"http://www.iqiyi.com/dongman/20130505/10.html",
                                                                    
                                                                    @"http://www.iqiyi.com/dongman/20130407/11.html",
                                                                    @"http://www.iqiyi.com/dongman/20130414/12.html",
                                                                    @"http://www.iqiyi.com/dongman/20130421/13.html",
                                                                    @"http://www.iqiyi.com/dongman/20130428/14.html",
                                                                    @"http://www.iqiyi.com/dongman/20130505/15.html",
                                                                    
                                                                    @"http://www.iqiyi.com/dongman/20130407/16.html",
                                                                    @"http://www.iqiyi.com/dongman/20130414/17.html",
                                                                    @"http://www.iqiyi.com/dongman/20130421/18.html",
                                                                    @"http://www.iqiyi.com/dongman/20130428/19.html",
                                                                    @"http://www.iqiyi.com/dongman/20130505/20.html",
                                                                    
                                                                    @"http://www.iqiyi.com/dongman/20130407/21.html",
                                                                    @"http://www.iqiyi.com/dongman/20130414/22.html",
                                                                    @"http://www.iqiyi.com/dongman/20130421/23.html",
                                                                    @"http://www.iqiyi.com/dongman/20130428/24.html",
                                                                    @"http://www.iqiyi.com/dongman/20130505/25.html",
                                                                    
                              @"http://www.iqiyi.com/dongman/20130407/c0a778d769a22727.html",
                              @"http://www.iqiyi.com/dongman/20130414/8d6929ed7ac9a7b8.html",
                              @"http://www.iqiyi.com/dongman/20130421/21eda9cfbff15519.html",
                              @"http://www.iqiyi.com/dongman/20130428/f54cac51ba17a84f.html",
                              @"http://www.iqiyi.com/dongman/20130505/90745cf1df1d637b.html",
                              @"http://www.iqiyi.com/dongman/20130512/6102135bcef439b7.html",
                              @"http://www.iqiyi.com/dongman/20130519/97bbd33b41332486.html",
                              @"http://www.iqiyi.com/dongman/20130526/4b1edd38f9f793ea.html",
                              @"http://www.iqiyi.com/dongman/20130602/7d4d4f934a41aa8f.html",
                              @"http://www.iqiyi.com/dongman/20130609/4ceadcc1906ee873.html",
                              @"http://www.iqiyi.com/dongman/20130616/084c8c28538b4ef8.html",
                              @"http://www.iqiyi.com/dongman/20130623/2c65b03dba0c3478.html",
                              @"http://www.iqiyi.com/dongman/20130630/c868faf904b8bc7a.html",
                              @"http://www.iqiyi.com/dongman/20130707/d48f6456119a5706.html",
                              @"http://www.iqiyi.com/dongman/20130714/1a5d53c3f03a9d8c.html",
                              
                              
                              
                              ]];
            _minVideoSetNum = 50;
            _maxVideoSetNum = _minVideoSetNum + urls.count - 1;
            
//            for (int i = 500; i < 1000; i ++) {
//                [urls addObject:[NSString stringWithFormat:@"http://www.iqiyi.com/dongman/20130505/%d.html", i+1]];
//            }
//            
//            for (int i = 500; --i >= 0;) {
//                [urls insertObject:[NSString stringWithFormat:@"http://www.iqiyi.com/dongman/20130505/%d.html", i+1] atIndex:0];
//            }
            
            // save video group info
            videoGroup.videoId = @(1234567890);
            videoGroup.videoName = @"进击的巨人";
            videoGroup.showType = @(1);
            videoGroup.src = @"爱奇艺";
            videoGroup.totalCount = @(0);
            videoGroup.maxId = @(_maxVideoSetNum);
            

//            videoGroup.videoId = @(1234567890);
//            videoGroup.videoName = @"进击的巨人";
//            videoGroup.showType = @(2);
//            videoGroup.src = @"爱奇艺";
//            videoGroup.totalCount = @(0);
//            videoGroup.maxId = @(urls.count);

            
            for (int i = 1; i <= urls.count; ++i) {
                Video *video = [Video MR_createEntity];
                video.setNum = @(_minVideoSetNum + i - 1);
                video.url = urls[i-1];
                video.brief = [NSString stringWithFormat:@"悠长的历史之中 %d", i];
                //,人类曾一度因被巨人捕食而崩溃。幸存下来的人们建造了一面巨大的墙壁,防止了巨人的入侵。不过,作为“和平”的代价,人类失去了到墙壁的外面去这一“自由”主人公艾伦·耶格尔对还没见过的外面的世界抱有兴趣。在他正做着到墙壁的外面去这个梦的时候,毁坏墙壁的大巨人出现了！";
//                video.videoGroup = videoGroup;
                [videoGroup addVideosObject:video];
            }
        }

    }];
}

- (VideoGroup *)extendDramaURLs:(TVDramaRequestType)requestType
{
    int min = _minVideoSetNum, max = _maxVideoSetNum;
    int delta = 15;
    VideoGroup *videoGroup = [VideoGroup MR_findFirst];
    if (requestType == TVDramaRequestTypeCurrent) {
        return videoGroup;
    }
    else  if (requestType == TVDramaRequestTypePrevious) {
        min -= delta;
        min = MAX(1, min);
    }
    else {
        max += delta;
    }
    NSLog(@"extendDramaURLs %d, count=%d, %d", requestType, max - min + 1, videoGroup.videos.count);
    for (int i = min; i <= max; ++i) {
        if (i >= _minVideoSetNum && i <= _maxVideoSetNum) {
            continue;
        }
        else {
            Video *video = [Video MR_createEntity];
            video.setNum = @(i);
            video.url = [NSString stringWithFormat:@"http://www.iqiyi.com/dongman/20130505/%d.html", i];
            video.brief =  [NSString stringWithFormat:@"悠长的历史之中 %d", i];
            //@"悠长的历史之中,人类曾一度因被巨人捕食而崩溃。幸存下来的人们建造了一面巨大的墙壁,防止了巨人的入侵。不过,作为“和平”的代价,人类失去了到墙壁的外面去这一“自由”主人公艾伦·耶格尔对还没见过的外面的世界抱有兴趣。在他正做着到墙壁的外面去这个梦的时候,毁坏墙壁的大巨人出现了！";
            [videoGroup addVideosObject:video];
        }
    }
    _minVideoSetNum = min;
    _maxVideoSetNum = max;
    videoGroup.maxId = @(_maxVideoSetNum + 100);
    [[NSManagedObjectContext MR_contextForCurrentThread] save:nil];
    NSLog(@"videos = %d", videoGroup.videos.count);
    return videoGroup;
}

- (VideoGroup *)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL curSetNum:(int *)curSetNumPtr requestType:(TVDramaRequestType)requestType
{
    if (_minVideoSetNum < 16) {
        [NSThread sleepForTimeInterval:3];
        return nil;
    }
    else if (_maxVideoSetNum > 100) {
        [NSThread sleepForTimeInterval:3];
        return nil;
    }
    
    VideoGroup *videoGroup = [self extendDramaURLs:requestType]; //[VideoGroup MR_findFirst];
    if (videoGroup) {
        Video *video = [videoGroup videoAtURL:URL];
        if (curSetNumPtr) {
            *curSetNumPtr = video.setNum.intValue;
            NSLog(@"requestDramaInfoWithURL curSetNum=%d (%p)", *curSetNumPtr, curSetNumPtr);
        }
    }
    // simulate loading interval
    [NSThread sleepForTimeInterval:3];
    
    return videoGroup;
}

- (NSString *)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURL:(NSString *)URL src:(NSString *)src
{
    // simulate loading interval
    NSURL *webURL = [NSURL URLWithString:URL];
    self.videoSrc = nil;
    
    [self performBlockInMainThread:^{
        if (self.webview == nil) {
            self.webview = [[[UIWebView alloc] initWithFrame:CGRectMake(-1000, -1000, 200, 200)] autorelease];
            self.webview.delegate = self;
            [[UIApplication sharedApplication].keyWindow addSubview:self.webview];
        }
        [self.webview loadRequest:[NSURLRequest requestWithURL:webURL]];
    } afterDelay:0];

    while (self.videoSrc.length == 0) {
        [NSThread sleepForTimeInterval:0.2];
    }
    
    return self.videoSrc;

    
    
//    [NSThread sleepForTimeInterval:2];
//
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    NSString *url = @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";
//    for (NSString *key in URLs) {
//        dict[key] = url;
//    }
//    return dict;
}

- (void)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL requestType:(TVDramaRequestType)requestType completionBlock:(void (^)(VideoGroup *videoGroup, int curSetNum))completionBlock
{
    [self performBlockInBackground:^{
        int curSetNum = 0;
        VideoGroup *videoGroup = [self tvDramaManager:manager requestDramaInfoWithURL:URL curSetNum:&curSetNum requestType:requestType];
        if (completionBlock) {
            completionBlock(videoGroup, curSetNum);
        }
    }];
}

- (void)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURL:(NSString *)URL src:(NSString *)src completionBlock:(void (^)(NSString *videoSrc))completionBlock
{
    [self performBlockInBackground:^{
        NSString *videoSrc = [self tvDramaManager:manager sniffVideoSrcWithURL:URL src:src];
        if (completionBlock) {
            completionBlock(videoSrc);
        }
    }];
}


#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self performBlockInMainThread:^{
        NSString *videoSrc = [self getCurrentVideoSrc];
        NSLog(@"videoSrc = %@", videoSrc);
        self.videoSrc = videoSrc;
    } afterDelay:2];
    
}

- (NSString *)getCurrentVideoSrc
{
    NSString *videoId = nil;
    NSString *currentVideoSrc = nil;
    
    //获取网页video标签id
    videoId = [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('video')[0].getAttribute('id')"];
    
    //获取网页视频src
    currentVideoSrc = [self.webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('%@').currentSrc", videoId]];
    //MTTLOG(@"current video src:%@", currentVideoSrc);
    //对乐视等类型html标签的适配
    if (currentVideoSrc == nil || currentVideoSrc.length < 1)
    {
        currentVideoSrc = [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('video')[0].getAttribute('src')"];
    }
    //对豆瓣影评视频等类型html标签的适配
    if (currentVideoSrc == nil || currentVideoSrc.length < 1)
    {
        NSString *regexString = @"\\bhttps?://[a-zA-Z0-9\\-.]+(?::(\\d+))?(?:(?:/[a-zA-Z0-9\\-._?,'+\\&%$=~*!():@\\\\]*)+)?";
        currentVideoSrc = [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('video')[0].innerHTML"];
        currentVideoSrc = [currentVideoSrc stringByMatching:regexString];
    }
    
    return currentVideoSrc;
}

@end

