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

@interface FakeTVDramaWebSource () <UIWebViewDelegate>
@property (nonatomic, retain) UIWebView *webview;
@property (nonatomic, copy) NSString *videoSrc;
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
        NSArray *videoGroups = [VideoGroup MR_findAll];
        if (videoGroups.count == 0) {
            VideoGroup *videoGroup = [VideoGroup MR_createEntity];
            
            NSArray *urls = @[
                              @"http://www.iqiyi.com/dongman/20130407/c0a778d769a22727.html",
                              @"http://www.iqiyi.com/dongman/20130414/8d6929ed7ac9a7b8.html",
                              @"http://www.iqiyi.com/dongman/20130421/21eda9cfbff15519.html",
                              @"http://www.iqiyi.com/dongman/20130428/f54cac51ba17a84f.html",
                              @"http://www.iqiyi.com/dongman/20130505/90745cf1df1d637b.html",
                              
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
                              
                              ];
            
            // save video group info
            videoGroup.videoId = @(1234567890);
            videoGroup.videoName = @"进击的巨人";
            videoGroup.showType = @(1);
            videoGroup.src = @"爱奇艺";
            videoGroup.totalCount = @(0);
            videoGroup.maxId = @(urls.count);
            

//            videoGroup.videoId = @(1234567890);
//            videoGroup.videoName = @"进击的巨人";
//            videoGroup.showType = @(2);
//            videoGroup.src = @"爱奇艺";
//            videoGroup.totalCount = @(0);
//            videoGroup.maxId = @(urls.count);

            
            for (int i = 1; i <= urls.count; ++i) {
                Video *video = [Video MR_createEntity];
                video.setNum = @(i);
                video.url = urls[i-1];
                video.brief = @"悠长的历史之中,人类曾一度因被巨人捕食而崩溃。幸存下来的人们建造了一面巨大的墙壁,防止了巨人的入侵。不过,作为“和平”的代价,人类失去了到墙壁的外面去这一“自由”主人公艾伦·耶格尔对还没见过的外面的世界抱有兴趣。在他正做着到墙壁的外面去这个梦的时候,毁坏墙壁的大巨人出现了！";
//                video.videoGroup = videoGroup;
                [videoGroup addVideosObject:video];
            }
        }

    }];
}

- (VideoGroup *)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL curSetNum:(int *)curSetNumPtr requestType:(TVDramaRequestType)requestType
{
    VideoGroup *videoGroup = [VideoGroup MR_findFirst];
    if (videoGroup) {
        int index = [videoGroup indexOfVideoWithURL:URL];
        if (index != NSNotFound) {
            Video *video = videoGroup.videos[index];
            if (curSetNumPtr) {
                *curSetNumPtr = video.setNum.intValue;
            }
        }
    }
    // simulate loading interval
    [NSThread sleepForTimeInterval:2];
    
    return videoGroup;
}

- (NSDictionary *)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURLs:(NSArray *)URLs
{
    // simulate loading interval
    NSURL *webURL = [NSURL URLWithString:URLs[0]];
    self.videoSrc = nil;
    
    [self performBlock:^{
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
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *key in URLs) {
        dict[key] = self.videoSrc;
    }
    return dict;
    
//    [NSThread sleepForTimeInterval:2];
//
//    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//    NSString *url = @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8";
//    for (NSString *key in URLs) {
//        dict[key] = url;
//    }
//    return dict;
}

#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self performBlock:^{
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

