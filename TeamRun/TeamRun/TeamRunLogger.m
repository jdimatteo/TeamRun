//
//  TeamRunLogger.m
//  teamrun
//
//  Created by John DiMatteo on 5/21/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunLogger.h"

typedef enum {TEAMRUN_LOG_TRACE, TEAMRUN_LOG_DEBUG, TEAMRUN_LOG_INFO, TEAMRUN_LOG_WARN, TEAMRUN_LOG_ERROR, TEAMRUN_LOG_TEMP_ESCALATION} LogLevel;

@interface TeamRunLogger ()

- (void)logWithLevel:(LogLevel)level message:(NSString*)message;

@end

@implementation TeamRunLogger

// todo: consider using CocoaLumberjack logging framework

- (void)logTrace:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:TEAMRUN_LOG_TRACE message:message];
}

- (void)logDebug:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:TEAMRUN_LOG_DEBUG message:message];
}

- (void)logInfo:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:TEAMRUN_LOG_INFO message:message];
}

- (void)logWarn:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:TEAMRUN_LOG_WARN message:message];
}

- (void)logError:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:TEAMRUN_LOG_ERROR message:message];
}

- (void)logTmp:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:TEAMRUN_LOG_TEMP_ESCALATION message:message];
}

- (void)logWithLevel:(LogLevel)level message:(NSString*)message
{
    /*
    static LogLevel currentLevel = TEAMRUN_LOG_WARN;
    
    if (level >= currentLevel)
    {
        NSLog(@"%@", message);
        
        if (self.scrollingLogText != nil)
        {
            [self.scrollingLogText setText:[NSString stringWithFormat:@"%@\n\n%@", [self.scrollingLogText text], message]];
            
            [self.scrollingLogText scrollRangeToVisible:NSMakeRange([self.scrollingLogText.text length], 0)];
        }
    }
    */
}

@end