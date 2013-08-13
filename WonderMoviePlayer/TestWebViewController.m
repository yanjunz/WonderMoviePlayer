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
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://v.m.liebao.cn"]]];
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
                    alert(v.currentTime); \
                    v.currentTime = 10; \
                    v.play();"]);
}

- (NSString *)exeJS:(NSString *)js {
    return [self.webview stringByEvaluatingJavaScriptFromString:js];
}
@end
