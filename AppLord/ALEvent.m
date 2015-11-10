//
//  ALEvent.m
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "ALEvent.h"

NSString *const ALEventAppLaunching = @"ALEventAppLaunching";
NSString *const ALEventSplashDismiss = @"ALEventSplashDismiss";
NSString *const ALEventAppWillResignActive = @"ALEventAppWillResignActive";
NSString *const ALEventAppDidEnterBackground = @"ALEventAppDidEnterBackground";
NSString *const ALEventAppWillEnterForeground = @"ALEventAppWillEnterForeground";
NSString *const ALEventAppDidBecomeActive = @"ALEventAppDidBecomeActive";
NSString *const ALEventAppWillTerminate = @"ALEventAppWillTerminate";

@implementation ALEvent

+ (instancetype)eventWithId:(NSString *)eventId userInfo:(NSDictionary *)userInfo
{
    ALEvent *event = [[self alloc] init];
    event.eventId = eventId;
    event.userInfo = userInfo;
    return event;
}

@end
