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

@interface ALContext ()
{
    NSMutableDictionary     *_modulesByName;
    NSMutableDictionary     *_moduleClassesByName;
    NSMutableDictionary     *_moduleClassesByInitEventId;
    NSMutableDictionary     *_modulesByStartEventId;

    NSMutableDictionary     *_servicesByName;
    NSMutableDictionary     *_serviceClassesByName;
    
    NSMutableDictionary     *_observerSetsByEventId;
    NSRecursiveLock         *_observerLock;
    
    BOOL                     _finishedStart;
    
    NSOperationQueue        *_taskQueue;
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
        _moduleClassesByInitEventId = [[NSMutableDictionary alloc] init];
        _modulesByStartEventId = [[NSMutableDictionary alloc] init];

        _servicesByName = [[NSMutableDictionary alloc] init];
        _serviceClassesByName = [[NSMutableDictionary alloc] init];
        
        _observerSetsByEventId = [[NSMutableDictionary alloc] init];
        _observerLock = [[NSRecursiveLock alloc] init];
        
        _info = [[ALContextInfo alloc] init];
        
        _taskQueue = [[NSOperationQueue alloc] init];
        _taskQueue.name = @"AppLord.ALContext.TaskQueue";
    }
    return self;
}

- (void)loadModulesWithEventId:(NSString *)eventId
{
    NSArray *initModules = [_moduleClassesByInitEventId objectForKey:eventId];
    if (initModules.count) {
        for (Class cls in initModules) {
            NSString *key = NSStringFromClass(cls);
            id<ALModule> module = [_modulesByName objectForKey:key];
            if (!module) {
                module = [[cls alloc] init];
                [_modulesByName setObject:module forKey:key];
                if ([module respondsToSelector:@selector(moduleDidInit:)]) {
                    [module moduleDidInit:self];
                }
                
                // make module record in start event
                NSString *startEventId = _finishedStart ? nil : ALEventAppLaunching;
                if ([cls resolveClassMethod:@selector(preferredStartEventId)]) {
                    startEventId = [cls preferredStartEventId];
                    NSParameterAssert(startEventId);
                }
                
                if (startEventId) {
                    NSMutableArray *startEventArray = [[_modulesByStartEventId objectForKey:startEventId] mutableCopy];
                    if (!startEventArray) {
                        startEventArray = [[NSMutableArray alloc] init];
                    }
                    [startEventArray addObject:module];
                    [_modulesByStartEventId setObject:startEventArray.copy forKey:startEventId];
                }
                
            }
        }
    }
}

- (void)startModulesWithEventId:(NSString *)eventId
{
    NSArray *startModules = [_modulesByStartEventId objectForKey:eventId];
    if (startModules.count) {
        for (id<ALModule> module in startModules) {
            if ([module respondsToSelector:@selector(moduleStart:)]) {
                [module moduleStart:self];
            }
        }
        [_modulesByStartEventId removeObjectForKey:eventId];
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

- (id)findModule:(Class)moduleClass
{
    NSString *key = NSStringFromClass(moduleClass);
    return [_modulesByName objectForKey:key];
}

- (void)sendEvent:(ALEvent *)event
{
    dispatch_block_t doSend = ^{
        NSString *eventId = event.eventId;
        
        // 初始化module
        [self loadModulesWithEventId:eventId];
        // 开始module
        [self startModulesWithEventId:eventId];
        
        // 发送事件
        [_observerLock lock];
        NSHashTable *observerSet = [[_observerSetsByEventId objectForKey:eventId] copy];
        if (observerSet.count) {
            [_observerLock unlock];
            NSEnumerator *enumerator = observerSet.objectEnumerator;
            id<ALModule> module = nil;
            while ((module = enumerator.nextObject)) {
                if ([module respondsToSelector:@selector(moduleDidReceiveEvent:)]) {
                    [module moduleDidReceiveEvent:event];
                }
            }
        } else if (observerSet) {
            [_observerSetsByEventId removeObjectForKey:eventId];
            [_observerLock unlock];
        }
    };
    if ([NSThread isMainThread]) {
        doSend();
    } else {
        dispatch_async(dispatch_get_main_queue(), doSend);
    }
}

- (void)sendEventWithId:(NSString *)eventId userInfo:(NSDictionary *)userInfo
{
    ALEvent *event = [ALEvent eventWithId:eventId userInfo:userInfo];
    [self sendEvent:event];
}

- (void)addEventObserver:(id)observer forEventId:(NSString *)eventId
{
    if (!observer || !eventId.length) {
        return;
    }
    
    [_observerLock lock];
    NSHashTable *observerSet = [_observerSetsByEventId objectForKey:eventId];
    if (!observerSet) {
        observerSet = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:0];
        [_observerSetsByEventId setObject:observerSet forKey:eventId];
    }
    [observerSet addObject:observer];
    [_observerLock unlock];
}

- (void)addEventObserver:(id)observer forEventIdArray:(NSArray *)eventIdArray
{
    for (NSString *eventId in eventIdArray) {
        [self addEventObserver:observer forEventId:eventId];
    }
}

- (void)registService:(Protocol *)proto withImpl:(Class)implClass
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

- (void)registModule:(Class)moduleClass
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

- (void)configurationModules
{
    NSArray *moduleClassArray = _moduleClassesByName.allValues;
    for (Class moduleClass in moduleClassArray) {
        
        NSString *initEventId = ALEventAppLaunching;
        if ([moduleClass resolveClassMethod:@selector(preferredInitEventId)]) {
            initEventId = [moduleClass preferredInitEventId];
            NSParameterAssert(initEventId);
        }
        
        NSMutableArray *initEventArray = [[_moduleClassesByInitEventId objectForKey:initEventId] mutableCopy];
        if (!initEventArray) {
            initEventArray = [[NSMutableArray alloc] init];
        }
        [initEventArray addObject:moduleClass];
        [_moduleClassesByInitEventId setObject:initEventArray.copy forKey:initEventId];
    }
}

#pragma mark - setup

- (void)setupWithLaunchOptions:(NSDictionary *)launchOptions launchTask:(NSArray *)launchTasks
{
    self.info.launchOptions = launchOptions;
    [self configurationModules];
    [self sendEventWithId:ALEventAppLaunching userInfo:launchOptions];
    [self runLaunchTasks:launchTasks];
    _finishedStart = YES;
}

- (void)runLaunchTasks:(NSArray *)launchTasks
{
    if (launchTasks.count) {
        
        NSMutableArray *tasks = [[NSMutableArray alloc] init];
        
        NSMutableDictionary *taskMap = [[NSMutableDictionary alloc] init];
        for (NSDictionary *taskInfo in launchTasks) {
            NSAssert([taskInfo isKindOfClass:[NSDictionary class]], @"launchTasks config error");
            
            NSString *className = [taskInfo objectForKey:@"className"];
            Class cls = NSClassFromString(className);
            if ([cls isSubclassOfClass:[NSOperation class]]) {
                
                NSOperation *task = [[cls alloc] init];
                [tasks addObject:task];
                [taskMap setObject:task forKey:className];
                
                //depedency
                NSArray *dependencyList = [[taskInfo objectForKey:@"dependency"] componentsSeparatedByString:@","];
                if (dependencyList.count) {
                    for (NSString *depedencyClass in dependencyList) {
                        NSOperation *preTask = [taskMap objectForKey:depedencyClass];
                        if (preTask) {
                            [task addDependency:preTask];
                        }
                    }
                }
            }
        }
        
        [_taskQueue addOperations:tasks waitUntilFinished:NO];
    }
}

#pragma mark - task

- (void)addTask:(NSOperation *)task
{
    [_taskQueue addOperation:task];
}

@end

ALContext * ALContextGet()
{
    return [ALContext sharedContext];
}