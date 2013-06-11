//
//  TeamRunSettings.m
//  teamrun
//
//  Created by John DiMatteo on 4/29/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//
//
// This file is part of TeamRun.
//
// TeamRun is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// TeamRun is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with TeamRun.  If not, see <http://www.gnu.org/licenses/>.

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

+ (BOOL)notificationsEnabled
{
    return [TeamRunSettings paceNotificationsEnabled] || [TeamRunSettings relativePositionNotificationsEnabled];
}

// note that I store paceNotificationsDisabled instead of paceNotificationsEnabled so that that it defaults to pace notifications disabled (since the BOOL NSUserDefaults initial value is false)
// same goes for relativePositionNotificationsDisabled.
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
    [[NSUserDefaults standardUserDefaults] setValue:@"test" forKey:@"log"];
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
