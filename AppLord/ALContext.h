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
@class ALTask;
@interface ALContext : NSObject

@property (nonatomic, strong, readonly) ALContextInfo *_Nonnull info;

+ (_Nonnull instancetype)sharedContext;

- (__nullable id)findService:( Protocol * _Nonnull )serviceProtocol;
- (__nullable id)findServiceByName:( NSString * _Nonnull )name;
- (__nullable id)findModule:(Class _Nonnull)moduleClass;

- (void)sendEvent:(ALEvent *_Nonnull)event;
- (void)sendEventWithId:(NSString *_Nonnull)eventId userInfo:(NSDictionary *_Nullable)userInfo;
- (void)addEventObserver:(id _Nonnull)observer forEventId:(NSString *_Nonnull)eventId;
- (void)addEventObserver:(id _Nonnull)observer forEventIdArray:(NSArray *_Nonnull)eventIdArray;

- (void)registService:(Protocol *_Nonnull)proto withImpl:(Class _Nonnull)implClass;
- (void)registModule:(Class _Nonnull)moduleClass;

/**
 *  初始化，在didFinishLaunching中调用
 *  @param launchOptions 启动参数
 *  @param launchTasks   启动任务项，格式参考 [{"name":"TestTask1", },...]
 */
- (void)setupWithLaunchOptions:(NSDictionary *_Nullable)launchOptions
                    launchTask:(NSArray *_Nullable)launchTasks;

- (void)addTask:(NSOperation *_Nonnull)task;

@end


FOUNDATION_EXTERN ALContext * _Nonnull ALContextGet();