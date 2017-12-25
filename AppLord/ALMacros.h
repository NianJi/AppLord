//
//  ALMacros.h
//  AppLord
//
//  Created by fengnianji on 16/11/16.
//  Copyright © 2016年 cnbluebox. All rights reserved.
//

#ifndef ALMacros_h
#define ALMacros_h


#define ALAnnotationDATA __attribute((used, section("__DATA,AppLord")))

/**
 *  Use this to annotation a `module`
 *  like this: @AppLordModule(MyModule)
 */
#define AppLordModule(modName) \
protocol ALModule; \
static char * kAppLordModule_##modName ALAnnotationDATA = "M:"#modName"";

/**
 *  Use this to annotation a `service`
 *  like this: @AppLordService(MyProtocol, MyClass)
 */
#define AppLordService(serviceName,cls) \
protocol ALModule; \
char * kAppLordService_##serviceName ALAnnotationDATA = "S:"#serviceName":"#cls"";

#endif /* ALMocros_h */
