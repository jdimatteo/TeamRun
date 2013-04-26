//
//  TeamRunUtility.h
//  teamrun
//
//  Created by John DiMatteo on 4/26/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeamRunUtility : NSObject

// note that [NSString stringWithFormat:@"%.2f", 0.339] rounds to @"0.34" -- this function doesn't round
NSString* truncateToTwoDecimals(const double value);

@end
