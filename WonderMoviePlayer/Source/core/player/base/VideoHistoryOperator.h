//
//  VideoHistoryOperator.h
//  mtt
//
//  Created by Zhuang Yanjun on 17/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VideoHistoryOperator <NSObject>
- (void)visitVideo:(Video *)video visit:(BOOL)visit;
- (void)removeAllVideoHistories;
@end
