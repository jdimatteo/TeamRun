//
//  TeamRunLogger.m
//  teamrun
//
//  Created by John DiMatteo on 5/21/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunLogger.h"


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
    
    [self logWithLevel:LOG_TRACE message:message];
}

- (void)logDebug:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_DEBUG message:message];
}

- (void)logInfo:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_INFO message:message];
}

- (void)logWarn:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_WARN message:message];
}

- (void)logError:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_ERROR message:message];
}

- (void)logTmp:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_TEMP_ESCALATION message:message];
}

- (void)logWithLevel:(LogLevel)level message:(NSString*)message
{
    static LogLevel currentLevel = 0;//LOG_DEBUG;
    
    if (level >= currentLevel)
    {
        NSLog(@"%@", message);
        [self.scrollingLogText setText:[NSString stringWithFormat:@"%@\n\n%@", [self.scrollingLogText text], message]];
        
        [self.scrollingLogText scrollRangeToVisible:NSMakeRange([self.scrollingLogText.text length], 0)];
    }
}

@end