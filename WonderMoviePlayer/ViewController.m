//
//  ViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "ViewController.h"
#import "WonderMoiveViewController.h"
#import "TestWebViewController.h"
#import "WonderAVMovieViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    /* Return YES for supported orientations. */
    return YES;
}

- (IBAction)onClickPlay:(id)sender {
//    WonderMoiveViewController *controller = [[WonderMoiveViewController alloc] init];
//    [self presentViewController:controller animated:YES completion:^{
//        NSLog(@"start to play");
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"m4v"];
//        [controller playMovieFile:[NSURL fileURLWithPath:path]];
//    }];
    WonderAVMovieViewController *controller = [[WonderAVMovieViewController alloc] init];
    [self presentViewController:controller animated:YES completion:^{
        [controller playMovieStream:[[NSBundle mainBundle] URLForResource:@"Movie" withExtension:@"m4v"]];
    }];
}

- (IBAction)onClickPlayRemote:(id)sender {
//    WonderMoiveViewController *controller = [[WonderMoiveViewController alloc] init];
    WonderAVMovieViewController *controller = [[WonderAVMovieViewController alloc] init];
    [self presentViewController:controller animated:YES completion:^{
        NSLog(@"start to play");
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"m4v"];
        [controller playMovieStream:[NSURL URLWithString:
//                                     @"http://hot.vrs.sohu.com/ipad1259067_4587696266952_4460388.m3u8?plat=null"
                                     @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"
//                                     @"http://v.youku.com/player/getM3U8/vid/148104913/type/flv/ts/1376293704/useKeyFrame/0/v.m3u8"
//                                     @"http://v.youku.com/player/getM3U8/vid/148703242/type/flv/ts/1376296533/useKeyFrame/0/v.m3u8"
//                                     @"http://v.youku.com/player/getRealM3U8/vid/XNDUwNjc4MzA4/type/video.m3u8"
//                                     @"http://jq.v.ismartv.tv/cdn/1/81/95e68bbdce46b5b8963b504bf73d1b/normal/slice/index.m3u8"
//                                     @"http://att.livem3u8.na.itv.cn/live/97acb1b2cbed4a4281a68356f8c2bd00.m3u8"
                                     ]];
    }];
}

- (IBAction)onClickWebView:(id)sender {
    [self.navigationController pushViewController:[[[TestWebViewController alloc] init] autorelease] animated:YES];
}

- (void)dealloc {
    [super dealloc];
}
@end
