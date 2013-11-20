//
//  ViewController.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-8.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController : UIViewController
- (IBAction)onClickPlay:(id)sender;
- (IBAction)onClickPlayRemote:(id)sender;
- (IBAction)onClickWebView:(id)sender;

@property (retain, nonatomic) IBOutlet UIImageView *loadingIndicator;
@end
