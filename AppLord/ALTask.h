//
//  ALTask.h
//  AppLordDemo
//
//  Created by fengnianji on 15/11/19.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  task helper class,
 *  1. use taskWithBlock method. you don't need call `finishWithError:`
 *  OR
 *  2. imp `executeTask` method.
 *     - DO NOT override `start` or `main` method.
 *     - you should call `finishWithError:` when the task is done!
 */
@interface ALTask : NSOperation

@property (nonatomic, strong) NSError *error;

/**
 *  create task with block.
 */
+ (instancetype)taskWithBlock:(NSError *(^)(ALTask *task))block;

/**
 *  require override, do the real job in this method, when finish, should call `finishWithError:`
 */
- (void)executeTask;

/**
 *  call this method when task is finished, if error is nil, consider it successed.
 */
- (void)finishWithError:(NSError *)error;

@end
