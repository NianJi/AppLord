//
//  ALContext.m
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "ALContext.h"
#import "ALModule.h"
#import "ALService.h"
#import "ALTask.h"
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

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

#define CLOCK(...) dispatch_semaphore_wait(_configLock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(_configLock);

@interface ALContext ()
{
    NSMutableDictionary<NSString *, id<ALModule>>      *_modulesByName;
    NSMutableDictionary<NSString *, Class<ALModule>>   *_moduleClassesByName;

    NSMutableDictionary<NSString *, id<ALService>>     *_servicesByName;
    NSMutableDictionary<NSString *, Class<ALService>>  *_serviceClassesByName;
    
    BOOL                     _finishedStart;
    
    NSOperationQueue        *_taskQueue;
    
    NSMutableDictionary     *_config;
    dispatch_semaphore_t     _configLock;
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        _modulesByName = [[NSMutableDictionary alloc] init];
        _moduleClassesByName = [[NSMutableDictionary alloc] init];

        _servicesByName = [[NSMutableDictionary alloc] init];
        _serviceClassesByName = [[NSMutableDictionary alloc] init];
        
        _taskQueue = [[NSOperationQueue alloc] init];
        _taskQueue.name = @"AppLord.ALContext.TaskQueue";
        
        _config = [[NSMutableDictionary alloc] init];
        _configLock = dispatch_semaphore_create(1);;
        
        [self readModuleAndServiceRegistedInSection];
    }
    return self;
}

- (void)readModuleAndServiceRegistedInSection
{
    NSArray<NSString *> *dataListInSection = AppLordReadConfigFromSection("AppLord");
    for (NSString *item in dataListInSection) {
        NSArray *components = [item componentsSeparatedByString:@":"];
        if (components.count >= 2) {
            NSString *type = components[0];
            if ([type isEqualToString:@"M"]) {
                NSString *modName = components[1];
                Class modCls = NSClassFromString(modName);
                if (modCls) {
                    [self registerModule:modCls];
                }
            } else if ([type isEqualToString:@"S"] && components.count == 3) {
                NSString *serName = components[1];
                NSString *serImplName = components[1];
                
                Protocol *serPro = NSProtocolFromString(serName);
                Class serCls = NSClassFromString(serImplName);
                if (serPro && serCls) {
                    [self registerService:serPro withImpl:serCls];
                }
            }
        }
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
    
    if ([_servicesByName objectForKey:NSStringFromProtocol(proto)]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ 协议已经注册", NSStringFromProtocol(proto)] userInfo:nil];
    }
    
    // Register Protocol
    NSString *protoName = NSStringFromProtocol(proto);
    if (protoName) {
        if ([implClass resolveClassMethod:@selector(globalVisible)]) {
            BOOL isGlobal = [implClass globalVisible];
            if (isGlobal) {
                id service = [[implClass alloc] init];
                [_servicesByName setObject:service forKey:protoName];
            } else {
                [_serviceClassesByName setObject:implClass forKey:protoName];
            }
        } else {
            [_serviceClassesByName setObject:implClass forKey:protoName];
        }
    }
}

- (id)findService:(Protocol *)serviceProtocol
{
    return [self findServiceByName:NSStringFromProtocol(serviceProtocol)];
}

- (id)findServiceByName:(NSString *)name
{
    id obj = [_servicesByName objectForKey:name];
    if (obj) {
        return obj;
    } else {
        Class cls = [_serviceClassesByName objectForKey:name];
        if (cls) {
            return [[cls alloc] init];
        }
    }
    return nil;
}

- (BOOL)existService:(NSString *)serviceName
{
    id obj = [_servicesByName objectForKey:serviceName];
    if (obj) {
        return YES;
    } else {
        Class cls = [_serviceClassesByName objectForKey:serviceName];
        if (cls) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - module

- (void)registerModule:(Class)moduleClass
{
    NSParameterAssert(moduleClass != nil);
    
    if (![moduleClass conformsToProtocol:@protocol(ALModule)]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ 模块不符合 ALModule 协议", NSStringFromClass(moduleClass)] userInfo:nil];
    }
    
    if ([_moduleClassesByName objectForKey:NSStringFromClass(moduleClass)]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"%@ 模块类已经注册", NSStringFromClass(moduleClass)] userInfo:nil];
    }
    
    NSString *key = NSStringFromClass(moduleClass);
    [_moduleClassesByName setObject:moduleClass forKey:key];
}

- (id)findModule:(Class)moduleClass
{
    NSString *key = NSStringFromClass(moduleClass);
    id<ALModule> module = [_modulesByName objectForKey:key];
    if (!module) {
        module = [self setupModuleWithClass:moduleClass];
    }
    return module;
}

- (id<ALModule>)setupModuleWithClass:(Class)moduleClass
{
    NSAssert([NSThread isMainThread], @"must run in main thread");
    id<ALModule> module = [[moduleClass alloc] init];
    [_modulesByName setObject:module forKey:NSStringFromClass(moduleClass)];
    if ([module respondsToSelector:@selector(moduleDidInit:)]) {
        [module moduleDidInit:self];
    }
    return module;
}

- (void)loadModules
{
    NSAssert([NSThread isMainThread], @"must run in main thread");
    NSArray *moduleClassArray = _moduleClassesByName.allValues;
    for (Class moduleClass in moduleClassArray) {
        
        if ([moduleClass resolveClassMethod:@selector(loadAfterLaunch)]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self setupModuleWithClass:moduleClass];
            });
            continue;
        }
        
        [self setupModuleWithClass:moduleClass];
    }
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
        CLOCK([_config setObject:value forKey:key];)
    }
}

- (id)objectForKey:(NSString *)key
{
    CLOCK(id object = [_config objectForKey:key]);
    return object;
}

- (NSString *)stringForKey:(NSString *)key
{
    CLOCK(id object = [_config objectForKey:key]);
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
    CLOCK(id object = [_config objectForKey:key]);
    if ([object isKindOfClass:[NSDictionary class]]) {
        return object;
    }
    else {
        return nil;
    }
}

- (NSArray *)arrayForKey:(NSString *)key
{
    CLOCK(id object = [_config objectForKey:key]);
    if ([object isKindOfClass:[NSArray class]]) {
        return object;
    }
    else {
        return nil;
    }
}

@end
