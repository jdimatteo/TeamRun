//
//  TeamRunModel.h
//  TeamRun
//
//  Created by John DiMatteo on 12/15/12.
//  Copyright (c) 2012 John DiMatteo. All rights reserved.
//

#import <Foundation/Foundation.h>

static const double MILES_PER_METER = 0.000621371;

@interface TeamRunModel : NSObject

@property (nonatomic) BOOL running;
@property (nonatomic) NSTimer* runningTimer;
@property (nonatomic) CFTimeInterval startRunningTime;
@property (nonatomic) double currentRunMiles;

- (CFGregorianUnits) currentRunDuration:(CFOptionFlags)unitFlags;

NSString* minutesPerMilePaceString(const double metersPerSecond);

@end
