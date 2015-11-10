//
//  ALEvent.h
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *_Nonnull const ALEventAppLaunching;
extern NSString *_Nonnull const ALEventSplashDismiss;
extern NSString *_Nonnull const ALEventAppWillResignActive;
extern NSString *_Nonnull const ALEventAppDidEnterBackground;
extern NSString *_Nonnull const ALEventAppWillEnterForeground;
extern NSString *_Nonnull const ALEventAppDidBecomeActive;
extern NSString *_Nonnull const ALEventAppWillTerminate;


@interface ALEvent : NSObject

@property (nonatomic, copy) NSString *_Nonnull eventId;
@property (nonatomic, strong) NSDictionary *_Nullable userInfo;

+ (_Nonnull instancetype)eventWithId:(NSString *_Nonnull)eventId userInfo:(NSDictionary *_Nullable)userInfo;

@end

