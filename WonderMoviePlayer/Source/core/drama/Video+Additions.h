//
//  Video+Additions.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/3/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import "Video.h"

@interface Video (Additions)

+ (Video *)videoWithVideoId:(NSString *)videoId srcIndex:(NSInteger)srcIndex setNum:(NSInteger)setNum;

+ (Video *)videoWithVideoId:(NSString *)videoId srcIndex:(NSInteger)srcIndex setNum:(NSInteger)setNum inContext:(NSManagedObjectContext *)context;

- (NSString *)displayName;

@end
