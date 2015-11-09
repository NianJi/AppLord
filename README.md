# AppLord

module and service management of ios app

## module

what is module? every business or task could be module.

how to impl?

first, create class:

```objc
#import <AppLord/AppLord.h>
@interface MyModule : NSObject <ALModule>
@end
```

then, impl like this:
```objc
@implementation MyModule
// regist the module, required
AL_EXPORT_MODULE

// module object init
- (void)moduleDidInit:(ALContext *)context
{
        
}

// module start it's business
- (void)moduleStart:(ALContext *)context
{
    
}

// receive events from other module
- (void)moduleDidReceiveEvent:(ALEvent *)context
{

}

// module will init when receive event which id is this
+ (ALEventId)preferredInitEventId
{

}
    
// module will start when receive event which id is this
+ (ALEventId)preferredStartEventId
{

}


@end
```
## service

we can receive events from other modules in a module, but it does not always meet the demand. we can't notify back to the sender. so we provide another way to transfer event between modules: `service`.

How to use?

Define your custom service
```objc
@protocol MyService <ALService>

- (void)doSomething;

@end
```

Impl it
```objc
@interface MyServiceImpl : NSObject <MyService>

@end

@implementation MyServiceImpl

// regist service
AL_EXPORT_SERVICE(MyService);

- (void)doSomething
{

}

// optional
+ (BOOL)globalVisible
{
    // if return YES, service will be always in the memory
}

@end
```

How to get the instance of service?
```objc
[ALContextGet() findServiceByName:@"MyService"];
```

