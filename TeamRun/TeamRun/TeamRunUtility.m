//
//  TeamRunUtility.m
//  teamrun
//
//  Created by John DiMatteo on 4/26/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunUtility.h"

@implementation TeamRunUtility

NSString* truncateToTwoDecimals(const double value)
{
    const int integer = value;
    const int hundreths = (value - integer)*100;
    
    return [NSString stringWithFormat:@"%d.%02d", integer, hundreths];
}

double absoluteValue(const double value)
{
    if (value < 0)
    {
        return -1.0 * value;
    }
    return value;
}

NSString* minutesPerMilePaceString(const double metersPerSecond, bool verbose)
{
    /* e.g. if currentSpeed = 1.95 (meters per second),
     *      then that is ~ 0.00121167345 miles per second (1.95 * MILES_PER_METER = 0.00121167),
     *      which is ~ 0.072700407 miles per minute (0.00121167345 * 60 = 0.072700407),
     *      which is ~ 13.7550811786 minutes per mile (1/0.072700407 = 13.7550811786),
     *      which is ~ 13:45 pace (minutes:second) per mile (.7550811786*60 = 45.304870716)
     *
     * it is easier to first get secondsPerMile pace, round that, and then
     * convert the rounded number to minutes per mile.
     *
     * e.g. 1.95 * MILES_PER_METER = 0.00121167 miles per second,
     *      1/0.00121167 = 825.307220613 seconds per mile,
     *      rounds to 825 seconds,
     *      floor(825/60) = 13 minutes,
     *      825 % 60 = 45 seconds,
     *      so the pace is 13:45 (minutes:seconds per mile)
     */
    
    const double milesPerSecond = metersPerSecond * MILES_PER_METER;
    
    NSString* noPace = verbose ? @"0 minutes and 0 seconds" : @"0:00";
    
    if (milesPerSecond > 0) // prevent divide by zero errors
    {
        const int secondsPerMile = round(1.0 / milesPerSecond);
        
        const int paceMinutes = secondsPerMile / 60;
        const int paceSeconds = secondsPerMile % 60;
        
        if (paceMinutes > 59)
        {
            return noPace;
        }
        else
        {
            return verbose ? [NSString stringWithFormat:@"%d minutes and %d seconds", paceMinutes, paceSeconds]
            : [NSString stringWithFormat:@"%d:%02d", paceMinutes, paceSeconds];
        }
    }
    return noPace;
}

@end
