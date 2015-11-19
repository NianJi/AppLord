//
//  Task2.m
//  AppLordDemo
//
//  Created by 念纪 on 15/11/19.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "Task2.h"

@implementation Task2

- (void)executeTask
{
    sleep(3);
    
    [self finishWithError:nil];
}

- (BOOL)needMainThread
{
    return NO;
}

@end
