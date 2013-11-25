//
//  MoviePlayerHandler.h
//  mtt
//
//  Created by Zhuang Yanjun on 13-9-9.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MoviePlayerHandler <NSObject>
@property (nonatomic, copy) void(^crossScreenBlock)();
@property (nonatomic, copy) void(^exitBlock)();
@end
