//
//  Video+Additions.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "Video+Additions.h"
#import "VideoGroup+Additions.h"
#import "VideoChannelInfo.h"
#import "VideoHistoryEntry.h"

@implementation Video (Additions)

+ (instancetype)videoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum
{
    return [self videoWithVideoId:videoId setNum:setNum inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (instancetype)videoWithVideoId:(NSString *)videoId setNum:(NSInteger)setNum inContext:(NSManagedObjectContext *)context
{
    return [Video MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"videoGroup.videoId == %@ AND setNum == %d", videoId, setNum] inContext:context];
}

+ (instancetype)videoWithWebURL:(NSString *)URL
{
    VideoChannelInfo *videoChannelInfo = [VideoChannelInfo MR_findFirstByAttribute:@"url" withValue:URL];
    return videoChannelInfo.video;
}

+ (instancetype)videoWithPath:(NSString *)path
{
    return [self videoWithPath:path inContext:[NSManagedObjectContext MR_contextForCurrentThread]];
}

+ (instancetype)videoWithPath:(NSString *)path inContext:(NSManagedObjectContext *)context
{
    return [Video MR_findFirstByAttribute:@"path" withValue:path inContext:context];
}

- (VideoChannelInfo *)videoChannelInfoAtSrcIndex:(NSInteger)srcIndex
{
    for (VideoChannelInfo *videoChannelInfo in self.videoChannelInfos) {
        if (videoChannelInfo.srcIndex.intValue == srcIndex) {
            return videoChannelInfo;
        }
    }
    return nil;
}

- (VideoChannelInfo *)videoChannelInfoAtWebURL:(NSString *)webURL
{
    for (VideoChannelInfo *videoChannelInfo in self.videoChannelInfos) {
//        if ([videoChannelInfo.url isEqualToString:webURL]) {
        if ([webURL rangeOfString:videoChannelInfo.url].location != NSNotFound) { // For some case webURL contains lots of extra info
            return videoChannelInfo;
        }
    }
    return nil;
}

- (VideoChannelInfo *)bestVideoChannelInfo
{
    VideoChannelInfo *videoChannelInfo = nil;
    if (self.videoHistoryEntry) {
        videoChannelInfo = [self videoChannelInfoAtSrcIndex:self.videoHistoryEntry.srcIndex.integerValue];
    }
    if (videoChannelInfo == nil) {
        videoChannelInfo = [self.videoChannelInfos anyObject];
    }
    return videoChannelInfo;
}

- (NSString *)displayName
{
    return [self.videoGroup displayNameForSetNum:self.setNum];
}

- (BOOL)hasLocalFile
{
    NSString * path = self.path;
    NSString * url = [self bestVideoChannelInfo].url;
    
    if(path && path.length > 0){
        return [[NSFileManager defaultManager] fileExistsAtPath:path];
    }
    else if ([url hasPrefix:@"file:"]) {
        NSURL *fileURL = [NSURL URLWithString:url];
        if ([fileURL isFileURL]) {
            return [[NSFileManager defaultManager] fileExistsAtPath:[fileURL relativePath]];
        }
    }
    else if([url hasPrefix:@"http:"] || [url hasPrefix:@"https:"]){
        return FALSE;
    }
    return FALSE;
}

- (BOOL)isPureLocalFile
{
    for (VideoChannelInfo *videoChannelInfo in self.videoChannelInfos) {
        if (videoChannelInfo.url.length > 0 && ![videoChannelInfo.url hasPrefix:@"file:"]) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)localFilePathChecked
{
    NSString * path = self.path;
    NSString * url = [self bestVideoChannelInfo].url;
    
    if(path && path.length > 0){
        BOOL ret =  [[NSFileManager defaultManager] fileExistsAtPath:path];
        if (ret) {
            return path;
        }
    }
    else if ([url hasPrefix:@"file:"]) {
        NSURL *fileURL = [NSURL URLWithString:url];
        if ([fileURL isFileURL]) {
            BOOL ret = [[NSFileManager defaultManager] fileExistsAtPath:[fileURL relativePath]];
            if (ret) {
                return [fileURL relativePath];
            }
        }
    }
    return nil;
}

- (void)saveCreateTimeInContext:(NSManagedObjectContext *)context
{
    NSDate *date = [NSDate date];
    self.createTime = @([date timeIntervalSince1970]);
}

- (void)saveCompletedTimeInContext:(NSManagedObjectContext *)context
{
    NSDate *date = [NSDate date];
    self.completedTime = @([date timeIntervalSince1970]);
}

- (void)clearTimeInContext:(NSManagedObjectContext *)context
{
    self.createTime = nil;
    self.completedTime = nil;
}

- (void)saveVideoSrc:(NSString *)videoSrc forSrcIndex:(NSInteger)srcIndex
{
    VideoChannelInfo *videoChannelInfo = [self videoChannelInfoAtSrcIndex:srcIndex];
    videoChannelInfo.videoSrc = videoSrc;
}

- (NSString *)webURLAtSrcIndex:(NSInteger)srcIndex
{
    return [self videoChannelInfoAtSrcIndex:srcIndex].url;
}

@end
