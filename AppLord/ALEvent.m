//
//  ALEvent.m
//  AppLord
//
//  Created by 念纪 on 15/11/9.
//  Copyright © 2015年 cnbluebox. All rights reserved.
//

#import "ALEvent.h"

@implementation ALEvent

+ (instancetype)eventWithId:(ALEventId)eventId userInfo:(NSDictionary *)userInfo
{
    ALEvent *event = [[self alloc] init];
    event.eventId = eventId;
    event.userInfo = userInfo;
    return event;
}

@end
