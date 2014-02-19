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
- (Video *)videoAtURL:(NSString *)URL;
- (Video *)videoAtSetNum:(NSNumber *)setNum;
- (void)setVideo:(Video *)video atSetNum:(NSNumber *)setNum inContext:(NSManagedObjectContext *)context;
- (NSArray *)sortedVideos:(BOOL)ascending;
- (BOOL)isValidDrama;
@end
