//
//  TestWebViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-13.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "TestWebViewController.h"
#import "WonderAVMovieViewController.h"
#import "WonderMPMovieViewController.h"
#import "FakeMovieDownloader.h"

@interface TestWebViewController ()

@end

@implementation TestWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    [NSClassFromString(@"WebView") _enableRemoteInspector];
    // Do any additional setup after loading the view from its nib.
    [self.webview loadRequest:[NSURLRequest requestWithURL:
                               [NSURL URLWithString:@"http://v.m.liebao.cn"]
//                               [NSURL URLWithString:@"http://pan.baidu.com"]
//                               [NSURL URLWithString:@"http://v.html5.qq.com"]
//                               [[NSBundle mainBundle] URLForResource:@"videoplay" withExtension:@"html"]
                               ]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerDidEnterFullScreen:) name:[NSString stringWithFormat:@"%@%@", @"UIMoviePlayerControllerD", @"idEnterFullscreenNotification"] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerExitFullScreen:) name:[NSString stringWithFormat:@"%@%@", @"UIMoviePlayerControllerWil", @"lExitFullscreenNotification"] object:nil];
    self.webview.allowsInlineMediaPlayback = YES;
    self.webview.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickBtn:(id)sender {
    // v.setAttribute('webkit-playsinline', 'YES');"
//    [self exeJS:@"\
//     var v = document.getElementsByTagName(\'video\')[0];\
//     v.play = function() {alert('hello');}"
//     ];
//                    v.play = function(){alert('aa');} 
    NSString *src = [self getCurrentVideoSrc];
    NSLog(@"src=%@", src);
    NSLog(@"%@", [[NSBundle mainBundle] pathForResource:@"video" ofType:@"js"]);
    NSString *js = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"video" withExtension:@"js"] encoding:NSUTF8StringEncoding error:NULL];
//    NSLog(@"js=%@", js);
    [self exeJS:js];
    NSLog(@"injection ok, %@", [self getCurrentVideoSrc]);

//    NSLog(@"%@\n", [self exeJS:@"\
//                    var v = document.getElementsByTagName(\'video\')[0]; \
//                    v.play = function(){window.location = 'qqvideo://play';};\
//                    v.autoplay=true;\
//                    "]);
                    //                    v.removeAttribute(\'controls\');
}

- (IBAction)onClickPlayOrg:(id)sender {
    [self.webview loadRequest:[NSURLRequest requestWithURL:
                               [NSURL URLWithString:@"http://v.m.liebao.cn"]]];
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

- (NSString *)exeJS:(NSString *)js {
    return [self.webview stringByEvaluatingJavaScriptFromString:js];
}

- (void)MPMoviePlayerDidEnterFullScreen:(NSNotification *)n{
    NSString *keyOfNotification = [NSString stringWithFormat:@"%@%@", @"MPAVControllerTi", @"ckNotification"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerProcessDidChanged:) name:keyOfNotification object:nil];
    
    
}

- (void)MPMoviePlayerExitFullScreen:(NSNotification *)n{
    NSString *keyOfNotification = [NSString stringWithFormat:@"%@%@", @"MPAVControllerTi", @"ckNotification"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:keyOfNotification object:nil];
}

- (void)MPMoviePlayerProcessDidChanged:(NSNotification *)n{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
//    NSString *src = [self getCurrentVideoSrc];
//    if (src.length > 0) {
//        NSLog(@"src=%@", src);
//        NSLog(@"%@\n", [self exeJS:@"\
//                        var v = document.getElementsByTagName(\'video\')[0]; \
//                        v.play = function(){window.location = 'qqvideo://play';};\
//                        v.autoplay=true;\
//                        "]);
//    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"shouldStartLoadWithRequest %@", request.URL);
    if ([@"qqvideo" isEqualToString:request.URL.scheme]) {
#ifdef MTT_FEATURE_WONDER_AVMOVIE_PLAYER
        __weak WonderAVMovieViewController *controller = [[WonderAVMovieViewController alloc] init];
        [controller setExitBlock:^{
            [controller dismissViewControllerAnimated:YES completion:nil];
        }];
        controller.movieDownloader = [[FakeMovieDownloader alloc] init];
        [controller setCrossScreenBlock:^{
            NSLog(@"cross screen");
        }];
        [self presentViewController:controller animated:YES completion:^{
            [controller playMovieStream:[NSURL URLWithString:[self getCurrentVideoSrc]]];
        }];
#else 
        WonderMPMovieViewController *controller = [[WonderMPMovieViewController alloc] init];
        [self presentViewController:controller animated:YES completion:^{
            [controller playMovieStream:[NSURL URLWithString:[self getCurrentVideoSrc]]];
        }];
#endif
        return NO;
    }
    return YES;
}
@end
