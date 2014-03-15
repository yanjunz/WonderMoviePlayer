//
//  VideoBookmarkEntry.h
//  mtt
//
//  Created by Zhuang Yanjun on 14/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VideoGroup;

@interface VideoBookmarkEntry : NSManagedObject

@property (nonatomic, retain) NSNumber * hasUpdate;
@property (nonatomic, retain) NSNumber * playingSetNum;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) VideoGroup *videoGroup;

@end
