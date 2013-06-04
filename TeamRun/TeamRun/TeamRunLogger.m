//
//  TeamRunLogger.m
//  teamrun
//
//  Created by John DiMatteo on 5/21/13.
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

#import "TeamRunLogger.h"

static UITextView* scrollingLogText = nil;

typedef enum {TEAMRUN_LOG_TRACE, TEAMRUN_LOG_DEBUG, TEAMRUN_LOG_INFO, TEAMRUN_LOG_WARN, TEAMRUN_LOG_ERROR, TEAMRUN_LOG_TEMP_ESCALATION} LogLevel;

void logWithLevel(LogLevel level, NSString* message);

// todo: consider using CocoaLumberjack logging framework

void setScrollingLogText(UITextView* newScrollingLogText)
{
    scrollingLogText = newScrollingLogText;
}

void logTrace(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    logWithLevel(TEAMRUN_LOG_TRACE, message);
}

void logDebug(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    logWithLevel(TEAMRUN_LOG_DEBUG, message);
}

void logInfo(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    logWithLevel(TEAMRUN_LOG_INFO, message);
}

void logWarn(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    logWithLevel(TEAMRUN_LOG_WARN, message);
}

void logError(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    logWithLevel(TEAMRUN_LOG_ERROR, message);
}

void logTmp(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    logWithLevel(TEAMRUN_LOG_TEMP_ESCALATION, message);
}

void logWithLevel(LogLevel level, NSString* message)
{
    static LogLevel currentLevel = TEAMRUN_LOG_WARN;
    
    if (level >= currentLevel)
    {
        NSLog(@"%@", message);
        
        if (scrollingLogText != nil)
        {
            [scrollingLogText setText:[NSString stringWithFormat:@"%@\n\n%@", [scrollingLogText text], message]];
            
            [scrollingLogText scrollRangeToVisible:NSMakeRange([scrollingLogText.text length], 0)];
        }
    }
}