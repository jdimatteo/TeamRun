//
//  TeamRunLogger.h
//  teamrun
//
//  Created by John DiMatteo on 5/17/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import <Foundation/Foundation.h>

// todo: preface this type def and enumerations with TEAM_RUN
typedef enum {LOG_TRACE, LOG_DEBUG, LOG_INFO, LOG_WARN, LOG_ERROR, LOG_TEMP_ESCALATION} LogLevel;


@interface TeamRunLogger : NSObject

@property UITextView *scrollingLogText;

- (void)logTrace:(NSString*)format,...;
- (void)logDebug:(NSString*)format,...;
- (void)logInfo:(NSString*)format,...;
- (void)logWarn:(NSString*)format,...;
- (void)logError:(NSString*)format,...;
- (void)logTmp:(NSString*)format,...;

@end
