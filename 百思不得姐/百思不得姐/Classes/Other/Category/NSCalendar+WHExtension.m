//
//  NSCalendar+WHExtension.m
//  百思不得姐
//
//  Created by 肖伟华 on 16/8/2.
//  Copyright © 2016年 XWH. All rights reserved.
//

#import "NSCalendar+WHExtension.h"

@implementation NSCalendar (WHExtension)
+ (instancetype)calendar
{
    if ([self respondsToSelector:@selector(calendarWithIdentifier:)])
    {
        return [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    }
    else
    {
        return [NSCalendar currentCalendar];
    }
}
@end
