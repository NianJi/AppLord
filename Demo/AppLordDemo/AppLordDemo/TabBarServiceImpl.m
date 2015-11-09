//
//  TabBarServiceImpl.m
//  AppLordDemo
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "TabBarServiceImpl.h"
#import "TabBarLauncherModule.h"

@implementation TabBarServiceImpl

AL_EXPORT_SERVICE(TabBarService);

- (UITabBarController *)tabBarController
{
    TabBarLauncherModule *module = [ALContextGet() findModule:[TabBarLauncherModule class]];
    return module.tabBarController;
}

- (void)switchToTabIndex:(NSUInteger)index
{
    TabBarLauncherModule *module = [ALContextGet() findModule:[TabBarLauncherModule class]];
    [module.tabBarController setSelectedIndex:index];
}

@end
