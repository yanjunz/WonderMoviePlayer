//
//  VideoGroup.h
//  mtt
//
//  Created by Zhuang Yanjun on 14/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Video, VideoBookmarkEntry;

@interface VideoGroup : NSManagedObject

@property (nonatomic, retain) NSString * picUrl;
@property (nonatomic, retain) NSNumber * setUpdateTime;
@property (nonatomic, retain) NSNumber * showType;
@property (nonatomic, retain) NSString * videoId;
@property (nonatomic, retain) NSString * videoName;
@property (nonatomic, retain) NSNumber * maxId;
@property (nonatomic, retain) NSNumber * totalCount;
@property (nonatomic, retain) VideoBookmarkEntry *videoBookmarkEntry;
@property (nonatomic, retain) NSSet *videos;
@end

@interface VideoGroup (CoreDataGeneratedAccessors)

- (void)addVideosObject:(Video *)value;
- (void)removeVideosObject:(Video *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

@end
