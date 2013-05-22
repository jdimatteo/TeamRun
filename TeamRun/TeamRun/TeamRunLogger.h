//
//  TeamRunLogger.h
//  teamrun
//
//  Created by John DiMatteo on 5/17/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeamRunLogger : NSObject

/* The macros below are the preferred way of using this logger. In order to use the macros, there 
   needs to be a TeamRunLogger available via "self.logger". These macros should be preferred over 
   the actual logger methods below because they include the line numbers and function names.

   example usage:
 
    self.logger = [[TeamRunLogger alloc] init];
    self.logger.scrollingLogText = self.scrollingText;
    
    LOG_DEBUG(@"Hi %d %d %d", 3, 2, 1);
 
   assuming the logging level is set equal to or greater than TEAMRUN_LOG_DEBUG and assuming this
   is called from TeamRunViewController viewDidLoad line 98 will result in the following written 
   to the console:
 
    2013-05-21 19:00:20.227 teamrun[8253:c07] DEBUG: -[TeamRunViewController viewDidLoad] [Line 98] Hi 3 2 1
 
   and the following appended to the end of scrollingText and the scrollingText is scrolled to 
   the bottom so that the new line is visible:
 
   DEBUG: -[TeamRunViewController viewDidLoad] [Line 98] Hi 3 2 1
 
 TODO: consider updating all code to use below macros, which would allow me to compile out all logging to improve performance, and easily change to a different logging library
 TODO: consider saving all logs to a file, and allowing a user to email me the log -- note that I should carefully review all log statements and verify that there is no personal info (e.g. GK names and GPS coordinates)
*/

#define LOG_TRACE() [self.logger logDebug:[[NSString alloc] initWithFormat:@"TRACE: %s [Line %d]", __PRETTY_FUNCTION__, __LINE__]]

#define LOG_DEBUG(fmt, ...) [self.logger logDebug:[[NSString alloc] initWithFormat:@"DEBUG: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]
#define LOG_INFO(fmt, ...) [self.logger logDebug:[[NSString alloc] initWithFormat:@"INFO: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]
#define LOG_WARN(fmt, ...) [self.logger logDebug:[[NSString alloc] initWithFormat:@"WARN: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]
#define LOG_ERROR(fmt, ...) [self.logger logDebug:[[NSString alloc] initWithFormat:@"ERROR: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]
#define LOG_TMP(fmt, ...) [self.logger logDebug:[[NSString alloc] initWithFormat:@"TMP: %s [Line %d] %@", __PRETTY_FUNCTION__, __LINE__, fmt], ##__VA_ARGS__]


@property UITextView *scrollingLogText;

- (void)logTrace:(NSString*)format,...;
- (void)logDebug:(NSString*)format,...;
- (void)logInfo:(NSString*)format,...;
- (void)logWarn:(NSString*)format,...;
- (void)logError:(NSString*)format,...;
- (void)logTmp:(NSString*)format,...;

@end
