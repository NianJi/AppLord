//
//  ALContext.m
//  AppLord
//
//  Created by fengnianji on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "ALContext.h"
#import "ALModule.h"
#import "ALTask.h"
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

NSString *const AppLordFirstIdleInMainNotification = @"AppLordFirstIdleInMainNotification";

NSArray<NSString *>* AppLordReadConfigFromSection(const char *sectionName){
    
#ifndef __LP64__
    const struct mach_header *mhp = NULL;
#else
    const struct mach_header_64 *mhp = NULL;
#endif
    
    NSMutableArray *configs = [NSMutableArray array];
    Dl_info info;
    if (mhp == NULL) {
        dladdr(AppLordReadConfigFromSection, &info);
#ifndef __LP64__
        mhp = (struct mach_header*)info.dli_fbase;
#else
        mhp = (struct mach_header_64*)info.dli_fbase;
#endif
    }
    
#ifndef __LP64__
    unsigned long size = 0;
    uint32_t *memory = (uint32_t*)getsectiondata(mhp, SEG_DATA, sectionName, & size);
#else /* defined(__LP64__) */
    unsigned long size = 0;
    uint64_t *memory = (uint64_t*)getsectiondata(mhp, SEG_DATA, sectionName, & size);
#endif /* defined(__LP64__) */
    
    for(int idx = 0; idx < size/sizeof(void*); ++idx){
        char *string = (char*)memory[idx];
        
        NSString *str = [NSString stringWithUTF8String:string];
        if(!str)continue;
        
        if(str) [configs addObject:str];
    }
    
    return configs;
}

@interface ALContext ()
{
    NSMutableDictionary<NSString *, id<ALModule>>      *_modulesByName;
    
    NSDictionary<NSString *, Class<ALService>>  *_serviceClassesByName;
    NSMutableDictionary<NSString *, Class<ALService>>  *_serviceClassesByNameM;
    
    BOOL                     _finishedStart;
    
    NSOperationQueue        *_taskQueue;
    
    NSMutableDictionary     *_config;
    dispatch_queue_t         _config_io_queue;
    dispatch_queue_t         _module_io_queue;
    
    NSArray *_launchTasks;
    NSMutableArray *_idleTasks;
}

@end

@implementation ALContext

+ (instancetype)sharedContext
{
    static ALContext *context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[self alloc] init];
    });
    return context;
}

- (void)setUp
{
    _modulesByName = [[NSMutableDictionary alloc] init];
    
    _serviceClassesByNameM = [[NSMutableDictionary alloc] init];
    
    _taskQueue = [[NSOperationQueue alloc] init];
    _taskQueue.name = @"AppLord.ALContext.TaskQueue";
    
    _config = [[NSMutableDictionary alloc] init];
    
    _config_io_queue = dispatch_queue_create("AppLord.ALContext.configIOQueue", DISPATCH_QUEUE_CONCURRENT);
    _module_io_queue = dispatch_queue_create("AppLord.ALContext.moduleIOQueue", DISPATCH_QUEUE_CONCURRENT);
    [self readModuleAndServiceRegistedInSection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(idleNotification:) name:AppLordFirstIdleInMainNotification object:nil];
}

- (void)readModuleAndServiceRegistedInSection
{
    NSArray<NSString *> *dataListInSection = AppLordReadConfigFromSection("AppLord");
    NSMutableDictionary *machoModules = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *machoServices = [[NSMutableDictionary alloc] init];
    for (NSString *item in dataListInSection) {
        NSArray *components = [item componentsSeparatedByString:@":"];
        if (components.count >= 2) {
            NSString *type = components[0];
            if ([type isEqualToString:@"M"]) {
                NSString *modName = components[1];
                Class modCls = NSClassFromString(modName);
                if (modCls) {
                    [machoModules setObject:modCls forKey:modName];
                }
            } else if ([type isEqualToString:@"S"] && components.count == 3) {
                NSString *serName = components[1];
                NSString *serImplName = components[2];
                
                Protocol *serPro = NSProtocolFromString(serName);
                Class serCls = NSClassFromString(serImplName);
                if (serPro && serCls) {
                    [machoServices setObject:serCls forKey:serName];
                }
            }
        }
    }
    _serviceClassesByName = machoServices.copy;
}

#pragma mark - Launch

- (void)setLaunchTasks:(NSArray *)launchTasks idleTasks:(NSArray *)idleTasks
{
    _launchTasks = launchTasks;
    _idleTasks = idleTasks.mutableCopy;
}

- (void)launch
{
    if (_launchTasks.count) {
        
        NSMutableArray *syncTasks = [[NSMutableArray alloc] init];
        NSMutableArray *asyncTasks = [[NSMutableArray alloc] init];
        for (NSString *taskClsName in _launchTasks) {
            Class<ALLaunchTask> taskCls = NSClassFromString(taskClsName);
            if (taskCls) {
                if ([taskCls respondsToSelector:@selector(launchTaskAsynchronous)] && [taskCls launchTaskAsynchronous]) {
                    [asyncTasks addObject:taskCls];
                } else {
                    [syncTasks addObject:taskCls];
                }
            }
        }
        
        // add operation
        _taskQueue.maxConcurrentOperationCount = 2;
        for (Class<ALLaunchTask> task in asyncTasks) {
            [_taskQueue addOperationWithBlock:^{
                if ([task respondsToSelector:@selector(appLaunch)]) {
                    [task appLaunch];
                }
            }];
        }
        
        // sync in main
        for (Class<ALLaunchTask> task in syncTasks) {
            if ([task respondsToSelector:@selector(appLaunch)]) {
                [task appLaunch];
            }
        }
        _launchTasks = nil;
    }
    
    [self postNotificationWhenIdle];
}

- (void)postNotificationWhenIdle
{
    NSNotification *idleNotification = [NSNotification notificationWithName:AppLordFirstIdleInMainNotification object:nil];
    [[NSNotificationQueue defaultQueue] enqueueNotification:idleNotification postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:@[NSDefaultRunLoopMode]];
}

- (void)idleNotification:(NSNotification *)notification
{
    if (_idleTasks.count) {
        
        NSString *taskName = [_idleTasks firstObject];
        Class<ALIdleLaunchTask> taskCls = NSClassFromString(taskName);
        if (taskCls) {
            if ([taskCls respondsToSelector:@selector(launchTaskAsynchronous)] && [taskCls launchTaskAsynchronous]) {
                [_taskQueue addOperationWithBlock:^{
                    if ([taskCls respondsToSelector:@selector(appFirstIdle)]) {
                        [taskCls appFirstIdle];
                    }
                }];
            } else {
                if ([taskCls respondsToSelector:@selector(appFirstIdle)]) {
                    [taskCls appFirstIdle];
                }
            }
        }
        
        [_idleTasks removeObjectAtIndex:0];
        [self postNotificationWhenIdle];
    } else {
        _idleTasks = nil;
    }
}

#pragma mark - service

- (void)registerService:(Protocol *)proto withImpl:(Class)implClass
{
    NSParameterAssert(proto != nil);
    NSParameterAssert(implClass != nil);
    
    if (![implClass conformsToProtocol:proto]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ 服务不符合 %@ 协议", NSStringFromClass(implClass), NSStringFromProtocol(proto)] userInfo:nil];
    }
    
    // Register Protocol
    dispatch_barrier_async(_module_io_queue, ^{
        NSString *protoName = NSStringFromProtocol(proto);
        if (protoName) {
            [_serviceClassesByNameM setObject:implClass forKey:protoName];
        }
    });
}

- (id)findService:(Protocol *)serviceProtocol
{
    return [self findServiceByName:NSStringFromProtocol(serviceProtocol)];
}

- (id)findServiceByName:(NSString *)name
{
    __block Class cls = [_serviceClassesByName objectForKey:name];
    if (!cls) {
        dispatch_sync(_module_io_queue, ^{
            cls = [_serviceClassesByNameM objectForKey:name];
        });
    }
    if (cls) {
        // a service could be a module
        id service = [self findModule:cls];
        if (!service) {
            service = [[cls alloc] init];
        }
        return service;
    }
    return nil;
}

- (BOOL)existService:(NSString *)serviceName
{
    __block Class cls = [_serviceClassesByName objectForKey:serviceName];
    if (!cls) {
        dispatch_sync(_module_io_queue, ^{
            cls = [_serviceClassesByNameM objectForKey:serviceName];
        });
    }
    if (cls) {
        return YES;
    }
    return NO;
}

#pragma mark - module

- (id)findModule:(Class)moduleClass
{
    NSString *key = NSStringFromClass(moduleClass);
    __block id<ALModule> module = nil;
    dispatch_sync(_module_io_queue, ^{
        module =  [_modulesByName objectForKey:key];
    });
    if (!module) {
        module = [self setupModuleWithClass:moduleClass];
    }
    return module;
}

- (id)findModuleByName:(NSString *)moduleName
{
    return [self findModule:NSClassFromString(moduleName)];
}

- (id<ALModule>)setupModuleWithClass:(Class)moduleClass
{
    id<ALModule> module = [[moduleClass alloc] init];
    dispatch_barrier_async(_module_io_queue, ^{
        [_modulesByName setObject:module forKey:NSStringFromClass(moduleClass)];
    });
    if ([module respondsToSelector:@selector(moduleDidInit:)]) {
        [module moduleDidInit:self];
    }
    return module;
}

- (void)loadModule:(Class)moduleClass
{
    [self setupModuleWithClass:moduleClass];
}

#pragma mark - task

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount
{
    [_taskQueue setMaxConcurrentOperationCount:maxConcurrentOperationCount];
}

- (NSInteger)maxConcurrentOperationCount
{
    return _taskQueue.maxConcurrentOperationCount;
}

- (void)addAsyncTasks:(NSArray<NSOperation *> *)tasks
{
    if (tasks.count) {
        [_taskQueue addOperations:tasks waitUntilFinished:NO];
    }
}

- (void)addTask:(NSOperation *)task
{
    [_taskQueue addOperation:task];
}

#pragma mark - config

- (void)setObject:(id)value forKey:(NSString *)key
{
    if (value && key) {
        dispatch_barrier_async(_config_io_queue, ^{
            [_config setObject:value forKey:key];
        });
    }
}

- (id)objectForKey:(NSString *)key
{
    __block id object;
    dispatch_sync(_config_io_queue, ^{
        object = [_config objectForKey:key];
    });
    return object;
}

- (NSString *)stringForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        return [object stringValue];
    }
    else {
        return nil;
    }
}

- (NSDictionary *)dictionaryForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return object;
    }
    else {
        return nil;
    }
}

- (NSArray *)arrayForKey:(NSString *)key
{
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSArray class]]) {
        return object;
    }
    else {
        return nil;
    }
}

@end
