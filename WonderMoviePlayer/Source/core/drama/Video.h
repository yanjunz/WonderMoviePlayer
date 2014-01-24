//
//  Video.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/19/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VideoGroup;

@interface Video : NSManagedObject

@property (nonatomic, strong) NSString * brief;
@property (nonatomic, strong) NSNumber * setNum;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSString * videoSrc;
@property (nonatomic, strong) VideoGroup *videoGroup;

@end
