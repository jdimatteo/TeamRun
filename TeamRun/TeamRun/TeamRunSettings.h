//
//  TeamRunSettings.h
//  teamrun
//
//  Created by John DiMatteo on 4/29/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeamRunSettings : NSObject

+ (BOOL)multiplayerMode;
+ (void)setMultiplayerMode:(const bool) enabled;

+ (int)secondsBetweenNotifications;
+ (void)setSecondsBetweenNotifications:(const int) seconds;

+ (int)targetSecondsPerMile;
+ (void)setTargetSecondsPerMile:(const int) seconds;

+ (BOOL)notificationsEnabled;

+ (BOOL)paceNotificationsEnabled;
+ (void)setPaceNotificationsEnabled:(const BOOL)enabled;

+ (BOOL)relativePositionNotificationsEnabled;
+ (void)setRelativePositionNotificationsEnabled:(const BOOL)enabled;

+ (BOOL)targetPaceEnabled;
+ (void)setTargetPaceEnabled:(const BOOL)enabled;

@end
