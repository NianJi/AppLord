//
//  ALService.h
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ALService <NSObject>

@optional
/**
 *  是否全局可见，默认service是使用时创建，如果是全局可见的，那么是持久化的一个service
 */
+ (BOOL)globalVisible;

@end
