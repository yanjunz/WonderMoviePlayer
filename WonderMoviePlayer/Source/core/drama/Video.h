//
//  Video.h
//  mtt
//
//  Created by Zhuang Yanjun on 20/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VideoChannelInfo, VideoGroup, VideoHistoryEntry;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSString * brief;
@property (nonatomic, retain) NSNumber * completedTime;
@property (nonatomic, retain) NSNumber * createTime;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * fileSize;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSNumber * setNum;
@property (nonatomic, retain) NSString * storageType;
@property (nonatomic, retain) NSSet *videoChannelInfos;
@property (nonatomic, retain) VideoGroup *videoGroup;
@property (nonatomic, retain) VideoHistoryEntry *videoHistoryEntry;
@end

@interface Video (CoreDataGeneratedAccessors)

- (void)addVideoChannelInfosObject:(VideoChannelInfo *)value;
- (void)removeVideoChannelInfosObject:(VideoChannelInfo *)value;
- (void)addVideoChannelInfos:(NSSet *)values;
- (void)removeVideoChannelInfos:(NSSet *)values;

@end
