//
//  UIImage+FillColor.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 12/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "UIImage+FillColor.h"

@implementation UIImage (FillColor)

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)backgroundImageWithSize:(CGSize)size content:(UIImage *)content
{
    CGRect rect = CGRectZero;
    rect.size = size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, rect);
    
    CGRect imageRect = CGRectMake((size.width - content.size.width) / 2, (size.height - content.size.height) / 2, content.size.width, content.size.height);
    CGContextSetShouldAntialias(context, YES);
    
    [content drawInRect:imageRect];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
