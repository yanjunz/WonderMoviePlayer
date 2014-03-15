//
//  VideoHistoryEntry.h
//  mtt
//
//  Created by Zhuang Yanjun on 14/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Video;

@interface VideoHistoryEntry : NSManagedObject

@property (nonatomic, retain) NSNumber * playedProgress;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSNumber * srcIndex;
@property (nonatomic, retain) Video *video;

@end
