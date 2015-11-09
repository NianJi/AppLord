//
//  ALService.h
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>

#undef AL_EXPORT_SERVICE
#define AL_EXPORT_SERVICE(prot) \
+ (void)load { [[ALContext sharedContext] registService:@protocol(prot) withImpl:[self class]]; }

@protocol ALService <NSObject>

@optional
/**
 *  是否全局可见，默认service是使用时创建，如果是全局可见的，那么是持久化的一个service
 */
+ (BOOL)globalVisible;

@end
