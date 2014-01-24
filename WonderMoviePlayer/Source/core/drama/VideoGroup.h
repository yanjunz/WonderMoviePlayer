//
//  VideoGroup.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/19/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Video;

@interface VideoGroup : NSManagedObject

@property (nonatomic, strong) NSNumber * maxId;
@property (nonatomic, strong) NSNumber * showType;
@property (nonatomic, strong) NSString * src;
@property (nonatomic, strong) NSNumber * totalCount;
@property (nonatomic, strong) NSNumber * videoId;
@property (nonatomic, strong) NSString * videoName;
@property (nonatomic, strong) NSSet *videos;
@end

@interface VideoGroup (CoreDataGeneratedAccessors)

- (void)addVideosObject:(Video *)value;
- (void)removeVideosObject:(Video *)value;
- (void)addVideos:(NSSet *)values;
- (void)removeVideos:(NSSet *)values;

@end
