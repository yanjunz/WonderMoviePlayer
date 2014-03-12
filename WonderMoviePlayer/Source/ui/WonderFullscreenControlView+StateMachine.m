//
//  WonderFullscreenControlView+StateMachine.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 11/22/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import "WonderFullscreenControlView+StateMachine.h"

@implementation WonderFullscreenControlView (StateMachine)

#pragma mark State Manchine
- (void)handleCommand:(MovieControlCommand)cmd param:(id)param notify:(BOOL)notify
{
//    NSArray *cmds = @[@"play", @"pause", @"end", @"replay", @"setProgress", @"buffer", @"unbuffer", @"playNext", @"error"];
//    NSArray *states = @[@"default", @"playing", @"paused", @"buffering", @"ended", @"preparing", @"errored"];
//    if (cmd != MovieControlCommandSetProgress) {
//        NSLog(@"handleCommand cmd=%@, state=%@, %@, %d", cmds[cmd], states[self.controlState], param, notify);
//    }
    
    if (cmd == MovieControlCommandEnd) {
        self.controlState = MovieControlStateEnded;
        
        if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceEnd:)]) {
            [self.delegate movieControlSourceEnd:self];
        }
    }
    else {
        switch (self.controlState) {
            case MovieControlStateDefault:
                if (cmd == MovieControlCommandPlay) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourcePlay:)]) {
                        [self.delegate movieControlSourcePlay:self];
                    }
                }
                break;
            case MovieControlStatePlaying:
                if (cmd == MovieControlCommandPause) {
                    self.controlState = MovieControlStatePaused;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourcePause:)]) {
                        [self.delegate movieControlSourcePause:self];
                    }
                }
                else if (cmd == MovieControlCommandSetProgress) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSource:setProgress:)]) {
                        [self.delegate movieControlSource:self setProgress:[(NSNumber *)param floatValue]];
                    }
                }
                else if (cmd == MovieControlCommandBuffer) {
                    self.controlState = MovieControlStateBuffering;
                    _bufferFromPaused = NO;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceBuffer:)]) {
                        [self.delegate movieControlSourceBuffer:self];
                    }
                }
                else if (cmd == MovieControlCommandPlayNext) {
                    self.controlState = MovieControlStatePreparing;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceWillPlayNext:)]) {
                        [self.delegate movieControlSourceWillPlayNext:self];
                    }
                }
                else if (cmd == MovieControlCommandError) {
                    self.controlState = MovieControlStateErrored;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceDidError:)]) {
                        [self.delegate movieControlSourceDidError:self];
                    }
                }
                break;
            case MovieControlStateEnded:
                if (cmd == MovieControlCommandReplay) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceReplay:)]) {
                        [self.delegate movieControlSourceReplay:self];
                    }
                }
                else if (cmd == MovieControlCommandSetProgress &&
                         [(NSNumber *)param floatValue] != 1) // iOS5 issue: setProgress cmd will be issued after the movie is end, just skip it
                {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSource:setProgress:)]) {
                        [self.delegate movieControlSource:self setProgress:[(NSNumber *)param floatValue]];
                    }
                }
                else if (cmd == MovieControlCommandPlayNext) {
                    self.controlState = MovieControlStatePreparing;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceWillPlayNext:)]) {
                        [self.delegate movieControlSourceWillPlayNext:self];
                    }
                }
                break;
            case MovieControlStatePaused:
                if (cmd == MovieControlCommandPlay) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceResume:)]) {
                        [self.delegate movieControlSourceResume:self];
                    }
                }
                else if (cmd == MovieControlCommandSetProgress) {
                    self.controlState = MovieControlStatePaused;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSource:setProgress:)]) {
                        [self.delegate movieControlSource:self setProgress:[(NSNumber *)param floatValue]];
                    }
                }
                else if (cmd == MovieControlCommandBuffer) {
                    self.controlState = MovieControlStateBuffering;
                    _bufferFromPaused = YES;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceBuffer:)]) {
                        [self.delegate movieControlSourceBuffer:self];
                    }
                }
                else if (cmd == MovieControlCommandPlayNext) {
                    self.controlState = MovieControlStatePreparing;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceWillPlayNext:)]) {
                        [self.delegate movieControlSourceWillPlayNext:self];
                    }
                }
                break;
            case MovieControlStateBuffering:
                if (cmd == MovieControlCommandPlay) { // FIXME! Need it?
                    self.controlState = MovieControlStatePlaying;
                    
                    // Actually there is no need to notify since no internal operation will trigger buffer
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourcePlay:)]) {
                        [self.delegate movieControlSourcePlay:self];
                    }
                }
                else if (cmd == MovieControlCommandPause) {
                    self.controlState = MovieControlStatePaused;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourcePause:)]) {
                        [self.delegate movieControlSourcePause:self];
                    }
                }
                else if (cmd == MovieControlCommandUnbuffer) {
                    if (_bufferFromPaused) {
                        self.controlState = MovieControlStatePaused;
                    }
                    else {
                        self.controlState = MovieControlStatePlaying;
                    }
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceUnbuffer:)]) {
                        [self.delegate movieControlSourceUnbuffer:self];
                    }
                }
                else if (cmd == MovieControlCommandPlayNext) {
                    self.controlState = MovieControlStatePreparing;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceWillPlayNext:)]) {
                        [self.delegate movieControlSourceWillPlayNext:self];
                    }
                }
                else if (cmd == MovieControlCommandError) {
                    self.controlState = MovieControlStateErrored;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceDidError:)]) {
                        [self.delegate movieControlSourceDidError:self];
                    }
                }
                break;
            case MovieControlStatePreparing:
                if (cmd == MovieControlCommandPlay ||
                    cmd == MovieControlCommandUnbuffer) {
                    self.controlState = MovieControlStatePlaying;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourcePlay:)]) {
                        [self.delegate movieControlSourcePlay:self];
                    }
                }
                else if (cmd == MovieControlCommandPlayNext) {
                    self.controlState = MovieControlStatePreparing;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceWillPlayNext:)]) {
                        [self.delegate movieControlSourceWillPlayNext:self];
                    }
                }
                else if (cmd == MovieControlCommandError) {
                    self.controlState = MovieControlStateErrored;
                    
//                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceDidError:)]) {
//                        [self.delegate movieControlSourceDidError:self];
//                    }
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceFailToPlayNext:)]) {
                        [self.delegate movieControlSourceFailToPlayNext:self];
                    }
                }
                break;
            case MovieControlStateErrored:
                if (cmd == MovieControlCommandPlayNext) {
                    self.controlState = MovieControlStatePreparing;
                    
                    if (notify && [self.delegate respondsToSelector:@selector(movieControlSourceWillPlayNext:)]) {
                        [self.delegate movieControlSourceWillPlayNext:self];
                    }
                }
                break;
        }
    }
    
    [self afterStateMachine];
}
@end
