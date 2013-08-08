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

@end
