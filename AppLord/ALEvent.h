//
//  ALEvent.h
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSInteger ALEventId;

enum {
    ALEventAppLaunching,        //应用进入
    ALEventSplashDismiss,       //闪屏消失
    ALEventAppWillResignActive,
    ALEventAppDidEnterBackground,
    ALEventAppWillEnterForeground,
    ALEventAppDidBecomeActive,
    ALEventAppWillTerminate
};

@interface ALEvent : NSObject

@property (nonatomic, assign) ALEventId eventId;
@property (nonatomic, strong) NSDictionary *_Nullable userInfo;

+ (_Nonnull instancetype)eventWithId:(ALEventId)eventId userInfo:(NSDictionary *_Nullable)userInfo;

@end

