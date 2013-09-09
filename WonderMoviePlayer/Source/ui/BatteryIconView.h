//
//  BatteryIconView.h
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-14.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BatteryIconView : UIView
@property (nonatomic, readonly) BOOL batteryMonitoringEnabled;
@property (nonatomic) CGFloat batteryLevel;

- (id)initWithBatteryMonitoringEnabled:(BOOL)batteryMonitoringEnabled;
@end
