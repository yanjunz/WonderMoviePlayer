//
//  TestWebViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-13.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "TestWebViewController.h"

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
    // Do any additional setup after loading the view from its nib.
    [self.webview loadRequest:[NSURLRequest requestWithURL:
//                               [NSURL URLWithString:@"http://v.m.liebao.cn"]
                               [[NSBundle mainBundle] URLForResource:@"videoplay" withExtension:@"html"]
                               ]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerDidEnterFullScreen:) name:[NSString stringWithFormat:@"%@%@", @"UIMoviePlayerControllerD", @"idEnterFullscreenNotification"] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerExitFullScreen:) name:[NSString stringWithFormat:@"%@%@", @"UIMoviePlayerControllerWil", @"lExitFullscreenNotification"] object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_webview release];
    [super dealloc];
}
- (IBAction)onClickBtn:(id)sender {
    NSLog(@"%@\n", [self exeJS:@"\
                    var v = document.getElementsByTagName(\'video\')[0]; \
                    alert(v.controls); \
                    v.controls=false;\
                    v.currentTime = 10; \
                    v.play();"]);
                    //                    v.removeAttribute(\'controls\');
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
@end
