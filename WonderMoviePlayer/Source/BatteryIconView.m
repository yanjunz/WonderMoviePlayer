//
//  BatteryIconView.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-14.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//
#import "WonderMoviePlayerConstants.h"
#import "BatteryIconView.h"

@interface BatteryIconView ()
@property (nonatomic, retain) UIImageView *electricityView;
@end

@implementation BatteryIconView

- (id)initWithBatteryMonitoringEnabled:(BOOL)batteryMonitoringEnabled
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        // Initialization code
        _batteryMonitoringEnabled = batteryMonitoringEnabled;
        if (_batteryMonitoringEnabled) {
            [UIDevice currentDevice].batteryMonitoringEnabled = YES;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBatteryLevelChanged) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
        }
        
        self.backgroundColor = [UIColor clearColor];
        UIImageView *bgImageView = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
        bgImageView.image = QQImage(@"videoplayer_battery_bg");
        bgImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:bgImageView];
        
        self.electricityView = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
        self.electricityView.image = QQImage(@"videoplayer_battery_electricity");
        self.electricityView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.electricityView];
        [self onBatteryLevelChanged];
    }
    return self;
}

- (void)dealloc
{
    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.electricityView = nil;
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat level = self.batteryLevel;
    if (level < 0) {
        level = 1;
    }
    if (level >= 0 && level <= 1) {
        CGFloat leftPadding = 2;
        CGFloat rightPadding = 4;
        self.electricityView.frame = CGRectMake(leftPadding, 0, level * (self.frame.size.width - leftPadding - rightPadding), self.frame.size.height);
    }
}

- (void)onBatteryLevelChanged
{
    self.batteryLevel = [UIDevice currentDevice].batteryLevel;
}

- (void)setBatteryLevel:(CGFloat)batteryLevel
{
    _batteryLevel = batteryLevel;
    [self setNeedsLayout];
}


@end
