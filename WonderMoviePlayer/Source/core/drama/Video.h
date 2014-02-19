//
//  Video.h
//  mtt
//
//  Created by Zhuang Yanjun on 11/2/14.
//  Copyright (c) 2014 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class VideoGroup;

@interface Video : NSManagedObject

@property (nonatomic, retain) NSString * brief;
@property (nonatomic, retain) NSNumber * setNum;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * videoSrc;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSNumber * resolution;
@property (nonatomic, retain) NSString * storageType;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * statusCode;
@property (nonatomic, retain) NSNumber * fileSize;
@property (nonatomic, retain) NSNumber * progress;
@property (nonatomic, retain) NSNumber * createTime;
@property (nonatomic, retain) NSString * completedTime;
@property (nonatomic, retain) VideoGroup *videoGroup;

@end
