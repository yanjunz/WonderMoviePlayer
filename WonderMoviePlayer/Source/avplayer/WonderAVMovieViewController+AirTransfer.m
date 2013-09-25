//
//  WonderAVMovieViewController+AirTransfer.m
//  mtt
//
//  Created by Zhuang Yanjun on 13-8-27.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#ifdef MTT_FEATURE_WONDER_AVMOVIE_PLAYER
#import "WonderAVMovieViewController+AirTransfer.h"

@implementation WonderAVMovieViewController (AirTransfer)

- (BOOL)isVideoWebpage
{
    return YES;
}

- (long)videoPlaybackTime
{
    CMTime currentTime = [self.player currentTime];
    if (CMTIME_IS_INVALID(currentTime)) {
        return 0;
    }
    else {
        // send end point is meanless
        if (_isEnd) {
            return 0;
        }
        double time = CMTimeGetSeconds(currentTime);
        return (long)time;
    }
}

- (long)videoTotalTime
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return 0;
    }
    else {
        double duration = CMTimeGetSeconds(playerDuration);
        return (long)duration;
    }
}

@end
#endif //MTT_FEATURE_WONDER_AVMOVIE_PLAYER
