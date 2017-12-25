//
//  ALModule.h
//  AppLord
//
//  Created by fengnianji on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLord/ALContext.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ALModule <NSObject>

/**
 *  module did create
 */
- (void)moduleDidInit:(ALContext *)context;

@end


@protocol ALLaunchTask <NSObject>

/**
 *  AppLaunched
 */
+ (void)appLaunch;

@optional
/**
 *  Can LaunchTask asynchronous load
 */
+ (BOOL)launchTaskAsynchronous;

@end


@protocol ALIdleLaunchTask <NSObject>

+ (void)appFirstIdle;

@optional
/**
 *  Can LaunchTask asynchronous load
 */
+ (BOOL)launchTaskAsynchronous;

@end

NS_ASSUME_NONNULL_END
