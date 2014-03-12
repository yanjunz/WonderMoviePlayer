//
//  UIImage+FillColor.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 12/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (FillColor)

+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)backgroundImageWithSize:(CGSize)size content:(UIImage *)content;

@end
