# AppLord

module and service management of ios app

## add to your project

management by `cocoapods`,  use:

    pod    'AppLord'

## module

what is module? every business or task could be module.

when the module init? when app launch or after app launch

how to impl?

first, create class:

```objc
#import <AppLord/AppLord.h>
@interface MyModule : NSObject <ALModule>
@end
```

then, impl like this:
```objc
@AppLordModule(MyModule) // Annotation for regist the module, required
@implementation MyModule

// module object init
- (void)moduleDidInit:(ALContext *)context
{
    // do some init thing
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

@AppLordService(MyService, MyServiceImpl) // regist MyService's Impl class: MyServiceImpl
@implementation MyServiceImpl

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
id<MyService> service = [[ALContext sharedContext] findServiceByName:@"MyService"];
// or
id<MyService> service = [[ALContext sharedContext] findService:@protocol(MyService)];
```

