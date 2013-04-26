//
//  TeamRunUtility.m
//  teamrun
//
//  Created by John DiMatteo on 4/26/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunUtility.h"

@implementation TeamRunUtility

+(NSString*) twoDecimalDigitStringWithoutRoundingFrom:(const double) value
{
    const int integer = value;
    const int hundreths = (value - integer)*100;
    
    return [NSString stringWithFormat:@"%d.%02d", integer, hundreths];
}

@end
