//
//  VideoChannelInfo.h
//  mtt
//
//  Created by Zhuang Yanjun on 14/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Video;

@interface VideoChannelInfo : NSManagedObject

@property (nonatomic, retain) NSNumber * srcIndex;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * videoSrc;
@property (nonatomic, retain) Video *video;

@end
