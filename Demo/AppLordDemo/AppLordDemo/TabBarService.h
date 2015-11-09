//
//  TabBarService.h
//  AppLordDemo
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <AppLord/AppLord.h>

@protocol TabBarService <ALService>

- (UITabBarController *)tabBarController;
- (void)switchToTabIndex:(NSUInteger)index;


@end

typedef id<TabBarService> TTabBarService;