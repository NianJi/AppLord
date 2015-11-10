//
//  ALContext.h
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLord/ALEvent.h>
#import <AppLord/ALContextInfo.h>

@protocol ALModule, ALService;
@interface ALContext : NSObject

@property (nonatomic, strong, readonly) ALContextInfo *_Nonnull info;

+ (_Nonnull instancetype)sharedContext;

- (__nullable id)findService:( Protocol * _Nonnull )serviceProtocol;
- (__nullable id)findServiceByName:( NSString * _Nonnull )name;
- (__nullable id)findModule:(Class _Nonnull)moduleClass;

- (void)sendEvent:(ALEvent *_Nonnull)event;
- (void)sendEventWithId:(NSString *_Nonnull)eventId userInfo:(NSDictionary *_Nullable)userInfo;

- (void)registService:(Protocol *_Nonnull)proto withImpl:(Class _Nonnull)implClass;
- (void)registModule:(Class _Nonnull)moduleClass;
- (void)destoryModule:(id _Nonnull)module;

- (void)setupWithLaunchOptions:(NSDictionary *_Nullable)launchOptions;

@end


FOUNDATION_EXTERN ALContext * _Nonnull ALContextGet();