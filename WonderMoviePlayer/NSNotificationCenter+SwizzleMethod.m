//
//  NSNotificationCenter+SwizzleMethod.m
//  WonderMoviePlayer
//
//  Created by Zhuang Yanjun on 13-8-19.
//  Copyright (c) 2013年 Tencent. All rights reserved.
//

#import "NSNotificationCenter+SwizzleMethod.h"
#import <objc/runtime.h>

@implementation NSNotificationCenter (SwizzleMethod)

+ (BOOL)swizzleMethod:(SEL)originSelector withMethod:(SEL)newSelector
{
    Method originMethod = class_getInstanceMethod(self, originSelector);
    Method newMethod = class_getInstanceMethod(self, newSelector);
    
    if (originMethod && newMethod) {
        if (class_addMethod(self, originSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
            class_replaceMethod(self, newSelector, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
        } else {
            method_exchangeImplementations(originMethod, newMethod);
        }
        return YES;
    }
    return NO;
}

+ (void)swizzleMethod
{
    [self swizzleMethod:@selector(postNotificationName:object:userInfo:) withMethod:@selector(swizzledPostNotificationName:object:userInfo:)];
}

- (void)swizzledPostNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo
{
    NSLog(@"\nPost Notification Name : %@\nObject: %@\nUserInfo:%@\n===\n===\n", aName, anObject, aUserInfo);
    [self swizzledPostNotificationName:aName object:anObject userInfo:aUserInfo];
}
@end
