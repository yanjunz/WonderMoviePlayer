//
//  Video.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/13/13.
//  Copyright (c) 2013 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VideoGroup;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * brief;
@property (nonatomic, retain) NSString * videoSrc;
@property (nonatomic, retain) NSNumber * setNum;
@property (nonatomic, retain) VideoGroup *videoGroup;

@end
