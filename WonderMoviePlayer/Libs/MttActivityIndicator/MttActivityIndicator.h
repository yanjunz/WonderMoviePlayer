//
//  MttActivityIndicator.h
//  mtt
//
//  Created by songfei on 13-11-14.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM( NSInteger, MttActivityIndicatorStyle)
{
    MttActivityIndicatorStyleBig,
    MttActivityIndicatorStyleColorBig,
    MttActivityIndicatorStyleMiddle,
    MttActivityIndicatorStyleColorMiddle,
    MttActivityIndicatorStyleSmall,
    MttActivityIndicatorStyleColorSmall,
};

@interface MttActivityIndicator : UIView

@property (nonatomic) MttActivityIndicatorStyle style;
@property (nonatomic,readonly) BOOL isAnimating;
@property (nonatomic) BOOL hidesWhenStopped;

@property (nonatomic) CGFloat speed;

- (id)initWithActivityIndicatorStyle:(MttActivityIndicatorStyle)style;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;

@end
