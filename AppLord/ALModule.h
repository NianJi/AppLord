//
//  ALModule.h
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppLord/ALContext.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ALModule <NSObject>

/**
 *  module did create
 */
- (void)moduleDidInit:(ALContext *)context;

@optional

/**
 *  config when load this module, init when main thread is idle
 */
+ (BOOL)loadAfterLaunch;

@end

NS_ASSUME_NONNULL_END
