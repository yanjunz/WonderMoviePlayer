//
//  VideoGroup+Additions.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "VideoGroup.h"

@class Video;

typedef enum {
    VideoGroupShowTypeNone,
    VideoGroupShowTypeGrid,
    VideoGroupShowTypeList,
} VideoGroupShowType;

@interface VideoGroup (Additions)
+ (instancetype)videoGroupWithVideoId:(NSString *)videoId;
+ (instancetype)videoGroupWithVideoId:(NSString *)videoId inContext:(NSManagedObjectContext *)context;

+ (NSString *)unRecognizedVideoIdPrefix;
+ (NSString *)generateVideoIdForUnRecognizedWebURL:(NSString *)webURL;
+ (BOOL)isVideoIdRecognized:(NSString *)videoId;

+ (NSString *)srcDescription:(NSInteger)srcIndex;
+ (NSInteger)srcIndex:(NSString *)srcDescription;

- (Video *)videoAtURL:(NSString *)URL;
- (Video *)videoAtSetNum:(NSNumber *)setNum;
- (NSArray *)sortedVideos:(BOOL)ascending;

- (BOOL)isValidDrama;       // Check if it is tv drama, false for movie
- (BOOL)isRecognized;       // Check if it is supported by server, false for the un-supported video

+ (NSString *)temporaryDisplayName;
- (NSString *)displayNameForSetNum:(NSNumber *)setNum;
- (NSArray *)downloadedVideos;
- (void)checkDownloadedVideosExist;
- (void)saveVideoSrc:(NSString *)videoSrc forSrcIndex:(NSInteger)srcIndex setNum:(NSInteger)setNum;
- (Video *)firstVideo;

@end
