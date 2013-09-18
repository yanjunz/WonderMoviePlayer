//
//  Test2ViewController.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-9-18.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "Test2ViewController.h"

@interface Test2ViewController ()

@end

@implementation Test2ViewController

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
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI / 180 * 360);
    rotationAnimation.duration = 1.0f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [self.loadingIndicator.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    NSLog(@"%@", self.loadingIndicator.layer.animationKeys);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_loadingIndicator release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setLoadingIndicator:nil];
    [super viewDidUnload];
}
- (IBAction)onClick1:(id)sender {
    NSLog(@"%@", self.loadingIndicator.layer.animationKeys);
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI / 180 * 360);
    rotationAnimation.duration = 1.0f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [self.loadingIndicator.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];

}
@end
