//
//  TeamRunSettings.m
//  teamrun
//
//  Created by John DiMatteo on 4/29/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunSettings.h"


@implementation TeamRunSettings

+ (int)secondsBetweenPaceNotifications
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"secondsBetweenPaceNotifications"];
}

+ (void)setSecondsBetweenPaceNotifications:(const int) seconds
{
    [[NSUserDefaults standardUserDefaults] setInteger:seconds forKey:@"secondsBetweenPaceNotifications"];
}

@end
