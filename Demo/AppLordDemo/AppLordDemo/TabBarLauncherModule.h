//
//  TabBarLauncherModule.h
//  AppLordDemo
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLord/AppLord.h>

@interface TabBarLauncherModule : NSObject <ALModule>

@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) UIWindow *window;

@end
