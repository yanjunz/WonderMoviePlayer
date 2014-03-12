//
//  VideoGroup+Additions.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "VideoGroup.h"

typedef enum {
    VideoGroupShowTypeNone,
    VideoGroupShowTypeGrid,
    VideoGroupShowTypeList,
} VideoGroupShowType;

@interface VideoGroup (Additions)
+ (VideoGroup *)videoGroupWithVideoId:(NSString *)videoId srcIndex:(NSInteger)srcIndex;
+ (VideoGroup *)videoGroupWithVideoId:(NSString *)videoId srcIndex:(NSInteger)srcIndex inContext:(NSManagedObjectContext *)context;

+ (NSString *)srcDescription:(NSInteger)srcIndex;
+ (NSInteger)srcIndex:(NSString *)srcDescription;

- (Video *)videoAtURL:(NSString *)URL;
- (Video *)videoAtSetNum:(NSNumber *)setNum;
- (void)setVideo:(Video *)video atSetNum:(NSNumber *)setNum inContext:(NSManagedObjectContext *)context;
- (NSArray *)sortedVideos:(BOOL)ascending;
- (BOOL)isValidDrama;       // Check if it is tv drama, false for movie
- (BOOL)isRecognized;       // Check if it is supported by server, false for the un-supported video
- (NSString *)displayNameForSetNum:(NSNumber *)setNum;
- (NSArray *)downloadedVideos;
- (void)checkDownloadedVideosExist;
@end
