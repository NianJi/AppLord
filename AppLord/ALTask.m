//
//  ALTask.m
//  AppLordDemo
//
//  Created by fengnianji on 15/11/19.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "ALTask.h"

typedef NS_ENUM(NSInteger, ALTaskState) {
    ALTaskStateCreate,
    ALTaskStateReady = 1,
    ALTaskStateLoading,
    ALTaskStateSuccessed,
    ALTaskStateFailure,
    ALTaskStateCanceled,
};

static inline BOOL ALTaskStateTransitionIsValid(ALTaskState fromState, ALTaskState toState) {
    
    switch (fromState) {
        case ALTaskStateReady:
        {
            switch (toState) {
                case ALTaskStateLoading:
                case ALTaskStateSuccessed:
                case ALTaskStateFailure:
                case ALTaskStateCanceled:
                    return YES;
                    break;
                default:
                    return NO;
                    break;
            }
            break;
        }
        case ALTaskStateLoading:
        {
            switch (toState) {
                case ALTaskStateSuccessed:
                case ALTaskStateFailure:
                case ALTaskStateCanceled:
                    return YES;
                    break;
                default:
                    return NO;
                    break;
            }
        }
        case (ALTaskState)0:
        {
            if (toState == ALTaskStateReady) {
                return YES;
            } else {
                return NO;
            }
        }
            
        default:
            return NO;
            break;
    }
}

@interface ALTask ()

@property (nonatomic, assign) ALTaskState state;
@property (nonatomic, strong, readonly) NSRecursiveLock *lock;
@property (nonatomic, copy) NSError *(^mainBlock)(ALTask *task);

@end

@implementation ALTask

@synthesize lock = _lock;

#pragma mark - init

+ (instancetype)taskWithBlock:(NSError *(^)(ALTask *))block
{
    ALTask *task = [[ALTask alloc] init];
    [task setMainBlock:block];
    return task;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.state = ALTaskStateReady;
    }
    return self;
}

- (NSRecursiveLock *)lock {
    if (!_lock) {
        _lock = [[NSRecursiveLock alloc] init];
    }
    return _lock;
}

#pragma mark - operation lifetime

- (void)start
{
    [self.lock lock];
    if ([self isReady]) {
        
        self.state = ALTaskStateLoading;
        NSLog(@"%@ begin", NSStringFromClass(self.class));
        [self.lock unlock];
 
        [self executeTask];
    } else {
        [self.lock unlock];
    }
}

#pragma mark - state

- (void)executeTask
{
    if (self.mainBlock) {
        NSError *error = self.mainBlock(self);
        [self finishWithError:error];
    } else {
        @throw [NSException exceptionWithName:@"ALTaskException" reason:@"need override" userInfo:nil];
    }
}

- (void)finishWithError:(NSError *)error
{
    [self.lock lock];
    if (![self isFinished]) {
       
        NSLog(@"%@ finish", NSStringFromClass(self.class));
        if (error) {
            self.error = error;
            self.state = ALTaskStateFailure;
        } else {
            self.state = ALTaskStateSuccessed;
        }

    }
    [self.lock unlock];
}

- (void)cancel
{
    [self.lock lock];
    
    if (![self isFinished])
    {
        self.state = ALTaskStateCanceled;
        [super cancel];
        NSLog(@"%@ cancel", NSStringFromClass(self.class));
    }
   
    [self.lock unlock];
}


- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isReady
{
    return self.state == ALTaskStateReady && [super isReady];
}

- (BOOL)isFinished
{
    return self.state == ALTaskStateSuccessed || self.state == ALTaskStateFailure || self.state == ALTaskStateCanceled;
}

- (BOOL)isExecuting
{
    return self.state == ALTaskStateLoading;
}

- (BOOL)isCancelled
{
    return self.state == ALTaskStateCanceled;
}

- (void)setState:(ALTaskState)state
{
    [self.lock lock];
    if (!ALTaskStateTransitionIsValid(_state, state)) {
        [self.lock unlock];
        return;
    }
    
    switch (state) {
        case ALTaskStateCanceled:
        {
            [self willChangeValueForKey:@"isExecuting"];
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isCancelled"];
            _state = state;
            [self didChangeValueForKey:@"isExecuting"];
            [self didChangeValueForKey:@"isFinished"];
            [self didChangeValueForKey:@"isCancelled"];
            break;
        }
        case ALTaskStateLoading:
        {
            [self willChangeValueForKey:@"isExecuting"];
            _state = state;
            [self didChangeValueForKey:@"isExecuting"];
            break;
        }
        case ALTaskStateSuccessed:
        case ALTaskStateFailure:
        {
            [self willChangeValueForKey:@"isFinished"];
            [self willChangeValueForKey:@"isExecuting"];
            _state = state;
            [self didChangeValueForKey:@"isFinished"];
            [self didChangeValueForKey:@"isExecuting"];
            break;
        }
        case ALTaskStateReady:
        {
            [self willChangeValueForKey:@"isReady"];
            _state = state;
            [self didChangeValueForKey:@"isReady"];
            break;
        }
        default:
        {
            _state = state;
            break;
        }
    }
    
    [self.lock unlock];
}

@end
