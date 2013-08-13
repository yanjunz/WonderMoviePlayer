//
//  TestWebViewController.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-13.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestWebViewController : UIViewController
@property (retain, nonatomic) IBOutlet UIWebView *webview;

- (IBAction)onClickBtn:(id)sender;
@end
