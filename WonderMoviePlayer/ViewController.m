//
//  ViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "ViewController.h"
#import "WonderMoiveViewController.h"

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
    WonderMoiveViewController *controller = [[WonderMoiveViewController alloc] init];
    [self presentViewController:controller animated:YES completion:^{
        NSLog(@"start to play");
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"m4v"];
        [controller playMovieFile:[NSURL fileURLWithPath:path]];
    }];
}

- (IBAction)onClickPlayRemote:(id)sender {
    WonderMoiveViewController *controller = [[WonderMoiveViewController alloc] init];
    [self presentViewController:controller animated:YES completion:^{
        NSLog(@"start to play");
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"m4v"];
        [controller playMovieStream:[NSURL URLWithString:
//                                     @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"
                                     @"http://v.youku.com/player/getM3U8/vid/148104913/type/flv/ts/1376293704/useKeyFrame/0/v.m3u8"
                                     ]];
    }];
}

- (void)dealloc {
    [super dealloc];
}
@end
