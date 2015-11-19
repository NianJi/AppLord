//
//  ALModule.h
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLord/ALContext.h>

#undef AL_EXPORT_MODULE
#define AL_EXPORT_MODULE \
+ (void)load { [[ALContext sharedContext] registModule:[self class]]; }

@protocol ALModule <NSObject>

/**
 *  模块被创建，一般来说app启动后就会创建
 */
- (void)moduleDidInit:(ALContext *_Nonnull)context;

/**
 *  模块开始执行自己的事务
 */
- (void)moduleStart:(ALContext *_Nonnull)context;

@optional

/**
 *  接收到了全局的事件
 */
- (void)moduleDidReceiveEvent:(ALEvent *_Nonnull)event;

/**
 *  这两个是配置方法，默认module在ALEventAppFirstLoad时执行 init 和 start，
 *  如果没有必要在启动就初始化或开始运行，那么就可以在这里配置接收到特定的eventId事件时才init或者start.
 */
+ (NSString *_Nonnull)preferredInitEventId;
+ (NSString *_Nonnull)preferredStartEventId;

@end

