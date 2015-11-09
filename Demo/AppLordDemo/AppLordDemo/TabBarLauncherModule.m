//
//  TabBarLauncherModule.m
//  AppLordDemo
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "TabBarLauncherModule.h"
#import "FirstViewController.h"
#import "SecondViewController.h"

@implementation TabBarLauncherModule

AL_EXPORT_MODULE

- (void)moduleDidInit:(ALContext *)context
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [[UIApplication sharedApplication] delegate].window = self.window;
    
    self.tabBarController = [[UITabBarController alloc] init];
    
    NSMutableArray *vcArray = [NSMutableArray array];
    {
        FirstViewController *vc = [[FirstViewController alloc] init];
        [vcArray addObject:vc];
    }
    {
        SecondViewController *vc = [[SecondViewController alloc] init];
        [vcArray addObject:vc];
    }
    self.tabBarController.viewControllers = vcArray.copy;
    
}

- (void)moduleStart:(ALContext *)context
{
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
}

- (void)moduleDidReceiveEvent:(ALEvent *)context
{
    
}

@end
