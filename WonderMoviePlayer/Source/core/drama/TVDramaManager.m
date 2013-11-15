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

- (BOOL)getDramaInfo:(TVDramaRequestType)requestType
{
    if (self.webURL.length > 0) {
        if ([self.delegate respondsToSelector:@selector(tvDramaManager:requestDramaInfoWithURL:curSetNum:requestType:)]) {
            int curSetNum = 0;
            self.videoGroup = [self.delegate tvDramaManager:self requestDramaInfoWithURL:self.webURL curSetNum:&curSetNum requestType:requestType];
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
            if (dict) {
                int index = [self.videoGroup indexOfVideoWithURL:self.webURL];
                if (index != NSNotFound) {
                    Video *video = self.videoGroup.videos[index];
                    video.videoSrc = dict[self.webURL];
                    return YES;
                }
            }
        }
    }
    return NO;
}

@end
