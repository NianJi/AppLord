//
//  ALContext.h
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ALModule, ALService;
@interface ALContext : NSObject

/**
 *  Get the singletion
 */
+ (_Nonnull instancetype)sharedContext;

@end

@interface ALContext (Service)

/**
 *  Regist a service with it's implement class
 */
- (void)registService:(Protocol *_Nonnull)proto withImpl:(Class _Nonnull)implClass;

/**
 *  Find the service implement of the protocol, return nil if not regist, create instance
 *  if not create
 */
- (__nullable id)findService:(Protocol *_Nonnull)serviceProtocol;

/**
 *  Just like `findService`, but you can pass a service's class name
 */
- (__nullable id)findServiceByName:(NSString *_Nonnull)name;

/**
 *  Figure out if a service is registed
 */
- (BOOL)existService:(NSString *_Nonnull)serviceName;


@end


@interface ALContext (Module)

/**
 *  regist a module with it's class name
 */
- (void)registModule:(Class _Nonnull)moduleClass;

/**
 *  init all the module registed
 */
- (void)loadModules;

/**
 *  Find the module instance
 */
- (__nullable id)findModule:(Class _Nonnull)moduleClass;

@end

@interface ALContext (Task)

/**
 *  the max concurrent of default operation queue
 */
@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;

/**
 *  batch run tasks, async on current thread.
 */
- (void)addAsyncTasks:(NSArray<NSOperation *> *_Nonnull)tasks;

/**
 *  add a task in the default background operation queue.
 */
- (void)addTask:(NSOperation *_Nonnull)task;

@end

@interface ALContext (Object)

- (void)setObject:(id _Nonnull)value forKey:(NSString *_Nonnull)key;
- (nullable id)objectForKey:(NSString *_Nonnull)key;

- (nullable NSString *)stringForKey:(NSString *_Nonnull)key;
- (nullable NSDictionary *)dictionaryForKey:(NSString *_Nonnull)key;
- (nullable NSArray *)arrayForKey:(NSString *_Nonnull)key;

@end
