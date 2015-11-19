//
//  Task4.m
//  AppLordDemo
//
//  Created by 念纪 on 15/11/19.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "Task4.h"

@implementation Task4

- (void)executeTask
{
    sleep(5);
    
    [self finishWithError:nil];
}

- (BOOL)needMainThread
{
    return NO;
}

@end
