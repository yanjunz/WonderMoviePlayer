//
//  TVDramaManager.m
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "TVDramaManager.h"
#import "VideoGroup.h"
#import "VideoGroup+VideoDetailSet.h"
#import "Video.h"

@implementation TVDramaManager

- (void)dealloc
{
    self.delegate = nil;
    self.webURL = nil;
    self.videoGroup = nil;
    [super dealloc];
}

- (BOOL)getCurrentSectionDramaInfo
{
    return [self getDramaInfoWithIndexOffset:0];
}

- (BOOL)getPreviousSectionDramaInfo
{
    return [self getDramaInfoWithIndexOffset:-1];
}

- (BOOL)getNextSectionDramaInfo
{
    return [self getDramaInfoWithIndexOffset:1];
}

// indexOffset should be -1,0,1
- (BOOL)getDramaInfoWithIndexOffset:(int)indexOffset
{
    if (self.webURL.length > 0) {
        if (indexOffset == 0 && [self.delegate respondsToSelector:@selector(tvDramaManager:requestCurrentSectionDramaInfoWithURL:curSetNum:)]) {
            int curSetNum = 0;
            self.videoGroup = [self.delegate tvDramaManager:self requestCurrentSectionDramaInfoWithURL:self.webURL curSetNum:&curSetNum];
            self.curSetNum = curSetNum;
            return YES;
        }
        else if (indexOffset < 0 && [self.delegate respondsToSelector:@selector(tvDramaManager:requestPreviousSectionDramaInfoWithURL:curSetNum:)]) {
            int curSetNum = 0;
            self.videoGroup = [self.delegate tvDramaManager:self requestPreviousSectionDramaInfoWithURL:self.webURL curSetNum:&curSetNum];
            self.curSetNum = curSetNum;
            return YES;
        }
        else if (indexOffset > 0 && [self.delegate respondsToSelector:@selector(tvDramaManager:requestNextSectionDramaInfoWithURL:curSetNum:)]) {
            int curSetNum = 0;
            self.videoGroup = [self.delegate tvDramaManager:self requestNextSectionDramaInfoWithURL:self.webURL curSetNum:&curSetNum];
            self.curSetNum = curSetNum;
            return YES;
        }
    }
    return NO;
}

- (BOOL)sniffVideoSource
{
    if (self.webURL.length > 0) {
        if ([self.delegate respondsToSelector:@selector(tvDramaManager:sniffVideoSrcWithURLs:)]) {
            NSDictionary *dict = [self.delegate tvDramaManager:self sniffVideoSrcWithURLs:@[self.webURL]];
            return dict != nil;
        }
    }
    return NO;
}

@end
