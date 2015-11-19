//
//  Task1.m
//  AppLordDemo
//
//  Created by 念纪 on 15/11/19.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "Task1.h"

@implementation Task1

- (void)executeTask
{
    sleep(2);
    
    [self finishWithError:nil];
}

- (BOOL)needMainThread
{
    return NO;
}

@end
