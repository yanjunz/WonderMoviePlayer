//
//  VideoGroup.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Video;

@interface VideoGroup : NSManagedObject

@property (nonatomic, retain) NSNumber * videoId;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * totalCount;
@property (nonatomic, retain) NSString * src;
@property (nonatomic, retain) NSString * videoName;
@property (nonatomic, retain) NSNumber * showType;
@property (nonatomic, retain) NSNumber * maxId;
@property (nonatomic, retain) NSOrderedSet *videos;
@end

@interface VideoGroup (CoreDataGeneratedAccessors)

- (void)insertObject:(Video *)value inVideosAtIndex:(NSUInteger)idx;
- (void)removeObjectFromVideosAtIndex:(NSUInteger)idx;
- (void)insertVideos:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeVideosAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInVideosAtIndex:(NSUInteger)idx withObject:(Video *)value;
- (void)replaceVideosAtIndexes:(NSIndexSet *)indexes withVideos:(NSArray *)values;
- (void)addVideosObject:(Video *)value;
- (void)removeVideosObject:(Video *)value;
- (void)addVideos:(NSOrderedSet *)values;
- (void)removeVideos:(NSOrderedSet *)values;
@end
