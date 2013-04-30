//
//  TeamRunSettings.m
//  teamrun
//
//  Created by John DiMatteo on 4/29/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunSettings.h"

@implementation TeamRunSettings

+ (int)secondsBetweenNotifications
{
    int seconds = [[NSUserDefaults standardUserDefaults] integerForKey:@"secondsBetweenPaceNotifications"];
    if (seconds <= 0) seconds = 60*5; // 5 minutes default

    return seconds;
}

+ (void)setSecondsBetweenNotifications:(const int) seconds
{
    [[NSUserDefaults standardUserDefaults] setInteger:seconds forKey:@"secondsBetweenPaceNotifications"];
}

// note that I store paceNotificationsDisabled (and paceNotificationsDisabled) instead of paceNotificationsEnabled
// (and paceNotificationsEnabled) so that that it defaults to pace notifications enabled (since the BOOL NSUserDefaults initial value is false)
+ (BOOL)paceNotificationsEnabled
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:@"paceNotificationsDisabled"];
}

+ (void)setPaceNotificationsEnabled:(const BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:!enabled forKey:@"paceNotificationsDisabled"];
}

+ (BOOL)relativePositionNotificationsEnabled
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:@"relativePositionNotificationsDisabled"];
}

+ (void)setRelativePositionNotificationsEnabled:(const BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:!enabled forKey:@"relativePositionNotificationsDisabled"];
}

+ (int)targetSecondsPerMile
{
    int seconds = [[NSUserDefaults standardUserDefaults] integerForKey:@"targetSecondsPerMile"];
    if (seconds <= 0) seconds = 60*9+30; // 9 minute 30 second mile pace default

    return seconds;
}

+ (void)setTargetSecondsPerMile:(const int) seconds
{
    [[NSUserDefaults standardUserDefaults] setInteger:seconds forKey:@"targetSecondsPerMile"];
}

+ (BOOL)targetPaceEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"targetPaceEnabled"];
}

+ (void)setTargetPaceEnabled:(const BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"targetPaceEnabled"];
}

@end
