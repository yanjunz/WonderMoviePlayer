//
//  VideoGroup+VideoDetailSet.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "VideoGroup+VideoDetailSet.h"
#import "Video.h"

@implementation VideoGroup (VideoDetailSet)
- (int)indexOfVideoWithURL:(NSString *)url
{
    int index = [self.videos indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        Video *v = obj;
        if ([v.url isEqualToString:url]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    return index;
}

- (Video *)videoAtSetNum:(NSNumber *)setNum
{
    int index = [self.videos indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        Video *v = obj;
        if (v.setNum.intValue == setNum.intValue) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    if (index != NSNotFound) {
        return [self.videos objectAtIndex:index];
    }
    else {
        return nil;
    }
}

- (void)setVideo:(Video *)video atSetNum:(NSNumber *)setNum
{
    // should use binary search for better performance
    int index = -1;
    for (int i = 0; i < self.videos.count; ++i) {
        Video *v = [self.videos objectAtIndex:i];
        if (v.setNum.intValue == setNum.intValue) {
            // the same one, just update it
            if (v != video) {
                NSLog(@"Warning: video detail data corrupted");
                [self replaceObjectInVideosAtIndex:i withObject:video];
                [v MR_deleteEntity];
            }
            return;
        }
        else if (v.setNum.intValue > setNum.intValue) {
            // find the larger one, just insert before it
            index = i;
            break;
        }
    }
    if (index < 0) { // add to the end
        [self addVideosObject:video];
    }
    else {
        [self insertObject:video inVideosAtIndex:index];
    }
}

- (void)addVideosObject:(Video *)value
{
    [self willChangeValueForKey:@"videos"];
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.videos];
    [tempSet addObject: value];
    self.videos = tempSet;
    [self didChangeValueForKey:@"videos"];
}

@end
