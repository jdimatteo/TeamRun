//
//  TeamRunUtility.h
//  teamrun
//
//  Created by John DiMatteo on 4/26/13.
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

#import <Foundation/Foundation.h>

@interface TeamRunUtility : NSObject

// note that [NSString stringWithFormat:@"%.2f", 0.339] rounds to @"0.34" -- this function doesn't round
NSString* truncateToTwoDecimals(const double value);
double absoluteValue(const double value);
NSString* minutesPerMilePaceString(const double metersPerSecond, bool verbose);

@end

static const double MILES_PER_METER = 0.000621371;
