//
//  FakeTVDramaWebSource.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/14/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "FakeTVDramaWebSource.h"
#import "Video.h"
#import "VideoGroup+VideoDetailSet.h"

@implementation FakeTVDramaWebSource

- (id)init
{
    if (self = [super init]) {
        [self setupDatabase];
    }
    return self;
}

- (void)setupDatabase
{
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
        NSArray *videoGroups = [VideoGroup MR_findAll];
        if (videoGroups.count == 0) {
            VideoGroup *videoGroup = [VideoGroup MR_createEntity];
            
            NSArray *urls = @[
                              @"http://www.iqiyi.com/dongman/20130407/c0a778d769a22727.html",
                              @"http://www.iqiyi.com/dongman/20130414/8d6929ed7ac9a7b8.html",
                              @"http://www.iqiyi.com/dongman/20130421/21eda9cfbff15519.html",
                              @"http://www.iqiyi.com/dongman/20130428/f54cac51ba17a84f.html",
                              @"http://www.iqiyi.com/dongman/20130505/90745cf1df1d637b.html",
                              ];
            
            // save video group info
            videoGroup.videoId = @(1234567890);
            videoGroup.videoName = @"进击的巨人";
            videoGroup.showType = @(1);
            videoGroup.src = @"爱奇艺";
            videoGroup.totalCount = @(0);
            videoGroup.maxId = @(urls.count);
            
            
            
            for (int i = 1; i <= urls.count; ++i) {
                Video *video = [Video MR_createEntity];
                video.setNum = @(i);
                video.url = urls[i-1];
                video.brief = @"悠长的历史之中,人类曾一度因被巨人捕食而崩溃。幸存下来的人们建造了一面巨大的墙壁,防止了巨人的入侵。不过,作为“和平”的代价,人类失去了到墙壁的外面去这一“自由”主人公艾伦·耶格尔对还没见过的外面的世界抱有兴趣。在他正做着到墙壁的外面去这个梦的时候,毁坏墙壁的大巨人出现了！";
//                video.videoGroup = videoGroup;
                [videoGroup addVideosObject:video];
            }
        }

    }];
}

- (VideoGroup *)tvDramaManager:(TVDramaManager *)manager requestDramaInfoWithURL:(NSString *)URL curSetNum:(int *)curSetNumPtr requestType:(TVDramaRequestType)requestType
{
    VideoGroup *videoGroup = [VideoGroup MR_findFirst];
    if (videoGroup) {
        int index = [videoGroup indexOfVideoWithURL:URL];
        if (index != NSNotFound) {
            Video *video = videoGroup.videos[index];
            if (curSetNumPtr) {
                *curSetNumPtr = video.setNum.intValue;
            }
        }
    }
    // simulate loading interval
    [NSThread sleepForTimeInterval:2];
    
    return videoGroup;
}

- (NSDictionary *)tvDramaManager:(TVDramaManager *)manager sniffVideoSrcWithURLs:(NSArray *)URLs
{
    return nil;
}

@end
