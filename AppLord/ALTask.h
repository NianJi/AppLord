//
//  ALTask.h
//  AppLordDemo
//
//  Created by fengnianji on 15/11/19.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  task base class, 
 *  DO NOT implement `start` or `main` method in subclass.
 */
@interface ALTask : NSOperation

@property (nonatomic, strong) NSError *error;

/**
 *  require override, do the real job in this method, when finish, should call `finishWithError:`
 */
- (void)executeTask;

/**
 *  call this method when task is finished, if error is nil, consider it successed.
 */
- (void)finishWithError:(NSError *)error;

/**
 *  task should be run in MainThread, need override, default YES
 */
- (BOOL)needMainThread;


@end
