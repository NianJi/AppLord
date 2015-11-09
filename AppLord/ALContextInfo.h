//
//  ALContextInfo.h
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ALContextInfo : NSObject

@property(nonatomic, strong) NSDictionary   *launchOptions;
@property(nonatomic, strong) NSURL          *lastOpenedURL;
@property(nonatomic, strong) NSDictionary   *lastRemoteNotification;

@end
