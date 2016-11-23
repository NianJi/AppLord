//
//  TabBarServiceImpl.m
//  AppLordDemo
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "TabBarServiceImpl.h"
#import "TabBarLauncherModule.h"

@AppLordService(TabBarService, TabBarServiceImpl)
@implementation TabBarServiceImpl

- (UITabBarController *)tabBarController
{
    TabBarLauncherModule *module = [[ALContext sharedContext] findModule:[TabBarLauncherModule class]];
    return module.tabBarController;
}

- (void)switchToTabIndex:(NSUInteger)index
{
    TabBarLauncherModule *module = [[ALContext sharedContext] findModule:[TabBarLauncherModule class]];
    [module.tabBarController setSelectedIndex:index];
}

@end
