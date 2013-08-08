//
//  UIView+Sizes.h
//  EnvelopeAnimation
//
//  Created by Zhuang Yanjun on 13-7-18.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Sizes)

@property (nonatomic) CGFloat left;
@property (nonatomic) CGFloat top;
@property (nonatomic) CGFloat right;
@property (nonatomic) CGFloat bottom;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;

@property (nonatomic) CGPoint origin;
@property (nonatomic) CGSize size;

-(void)setAnchorPoint:(CGPoint)anchorPoint;

@end

