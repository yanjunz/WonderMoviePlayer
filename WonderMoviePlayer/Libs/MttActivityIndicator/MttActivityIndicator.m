//
//  MttActivityIndicator.m
//  mtt
//
//  Created by songfei on 13-11-14.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "MttActivityIndicator.h"
//#import "UIImageEx.h"

#define INDICATOR_SIZE_BIG      69
#define INDICATOR_SIZE_MIDDLE   56
#define INDICATOR_SIZE_SMALL    20

#define INDICATOR_SPEED_DEFAULT 0.25

NSString *const MttActivityIndicatorAnimationKey = @"MttActivityIndicatorAnimationKey";

@interface MttActivityIndicator()

@property (nonatomic,retain) UIImageView* imageView;

@end


@implementation MttActivityIndicator


- (id)initWithActivityIndicatorStyle:(MttActivityIndicatorStyle)style
{
    self = [super init];
    if(self)
    {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [_imageView setHidden:YES];
        [self setBackgroundColor:[UIColor clearColor]];
        
        [self addSubview:_imageView];
        
        _speed = INDICATOR_SPEED_DEFAULT;
        _hidesWhenStopped = YES;
        
        [self setStyle:style];
    }
    return self;
}

- (void)dealloc
{
    [_imageView release];
    
    [super dealloc];
}

- (void)setStyle:(MttActivityIndicatorStyle)style
{
    CGRect frame = CGRectZero;
    UIImage* image = nil;
    
    switch (style) {
        case MttActivityIndicatorStyleBig:
            frame = CGRectMake(0, 0, INDICATOR_SIZE_BIG, INDICATOR_SIZE_BIG);
            image = QQCommonImage(@"b"); //[UIImageEx loadAndCacheImageFromApp:@"common_activityindicator_b"];
            break;
            
        case MttActivityIndicatorStyleColorBig:
            frame = CGRectMake(0, 0, INDICATOR_SIZE_BIG, INDICATOR_SIZE_BIG);
            image = QQCommonImage(@"color_b");  //[UIImageEx loadAndCacheImageFromApp:@"common_activityindicator_color_b"];
            break;
            
        case MttActivityIndicatorStyleMiddle:
            frame = CGRectMake(0, 0, INDICATOR_SIZE_MIDDLE, INDICATOR_SIZE_MIDDLE);
            image = QQCommonImage(@"m");  //[UIImageEx loadAndCacheImageFromApp:@"common_activityindicator_m"];
            break;
            
        case MttActivityIndicatorStyleColorMiddle:
            frame = CGRectMake(0, 0, INDICATOR_SIZE_MIDDLE, INDICATOR_SIZE_MIDDLE);
            image = QQCommonImage(@"color_m");  //[UIImageEx loadAndCacheImageFromApp:@"common_activityindicator_color_m"];
            break;
            
        case MttActivityIndicatorStyleSmall:
            frame = CGRectMake(0, 0, INDICATOR_SIZE_SMALL, INDICATOR_SIZE_SMALL);
            image = QQCommonImage(@"s");  //[UIImageEx loadAndCacheImageFromApp:@"common_activityindicator_s"];
            break;
            
        case MttActivityIndicatorStyleColorSmall:
            frame = CGRectMake(0, 0, INDICATOR_SIZE_SMALL, INDICATOR_SIZE_SMALL);
            image = QQCommonImage(@"color_s");  //[UIImageEx loadAndCacheImageFromApp:@"common_activityindicator_color_s"];
            break;
            
        default:
            break;
    }
    
    [self setFrame:frame];
    [self.imageView setFrame:frame];
    [self.imageView setImage:image];
    
}

- (void)setSpeed:(CGFloat)speed
{
    _speed = speed;
    
    [self startAnimating];
}

- (void)startAnimating
{
    [self stopAnimating];
    
    [self.imageView setHidden:NO];
    
    CABasicAnimation *theAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    theAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    theAnimation.toValue = [NSNumber numberWithFloat:1.0];
    theAnimation.cumulative = YES;
    theAnimation.duration = self.speed;
    theAnimation.repeatCount = HUGE_VAL;
    theAnimation.removedOnCompletion = YES;
    
    [self.imageView.layer addAnimation:theAnimation forKey:MttActivityIndicatorAnimationKey];
}

- (void)stopAnimating
{
    [self.imageView.layer removeAllAnimations];
    
    if(self.hidesWhenStopped)
    {
        [self.imageView setHidden:YES];
    }
    
}

- (BOOL)isAnimating
{
    CAAnimation *animation = [self.imageView.layer animationForKey:MttActivityIndicatorAnimationKey];
    if (animation) {
        return YES;
    } else {
        return NO;
    }
}

@end
