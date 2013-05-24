//
//  TeamRunLogger.h
//  teamrun
//
//  Created by John DiMatteo on 5/17/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeamRunLogger : NSObject

/* these macros should be used instead of directly calling the TeamRunLogger methods.
   the macros have some advantages over the methods:
   
   1. line number and method name are included from where the logging statement is
   2. the logging framework can be changed (e.g. if I later choose to switch to CocoaLumberjack we can make all the changes in TeamRunLogger instead of changing every logging line directly)
   3. we can remove all the logging at compile time by replacing the below macro definitions with empty definitions
 */

#define LOG_TRACE() [TeamRunLogger logTrace:[NSString stringWithFormat:@"TRACE: %s [Line %d]", __PRETTY_FUNCTION__, __LINE__]]

#define LOG_DEBUG(fmt, ...) [TeamRunLogger logDebug:[NSString stringWithFormat:@"DEBUG: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]
#define LOG_INFO(fmt, ...) [TeamRunLogger logInfo:[NSString stringWithFormat:@"INFO: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]
#define LOG_WARN(fmt, ...) [TeamRunLogger logWarn:[NSString stringWithFormat:@"WARN: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]
#define LOG_ERROR(fmt, ...) [TeamRunLogger logError:[NSString stringWithFormat:@"ERROR: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]
#define LOG_TMP(fmt, ...) [TeamRunLogger logTmp:[NSString stringWithFormat:@"TMP: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]

// todo: make below C functions instead of objective C methods

+ (void)logTrace:(NSString*)format,...;
+ (void)logDebug:(NSString*)format,...;
+ (void)logInfo:(NSString*)format,...;
+ (void)logWarn:(NSString*)format,...;
+ (void)logError:(NSString*)format,...;
+ (void)logTmp:(NSString*)format,...;
+ (void)setScrollingLogText:(UITextView*)scrollingLogText;

@end
