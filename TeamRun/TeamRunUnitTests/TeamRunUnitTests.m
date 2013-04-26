//
//  TeamRunUnitTests.m
//  TeamRunUnitTests
//
//  Created by John DiMatteo on 4/26/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunUnitTests.h"
#import "TeamRunUtility.h"

@implementation TeamRunUnitTests

// note: implement setUp and tearDown if necessary (calling super before and after respectively)

- (void)testTwoDecimalDigitStringWithoutRoundingFrom
{
    NSString* s = [TeamRunUtility twoDecimalDigitStringWithoutRoundingFrom:0.35];
    STAssertEqualObjects(s, @"0.35", nil);
    
    s = [TeamRunUtility twoDecimalDigitStringWithoutRoundingFrom:0.354];
    STAssertEqualObjects(s, @"0.35", nil);
    
    s = [TeamRunUtility twoDecimalDigitStringWithoutRoundingFrom:0.356];
    STAssertEqualObjects(s, @"0.35", nil);

    s = [TeamRunUtility twoDecimalDigitStringWithoutRoundingFrom:135.359];
    STAssertEqualObjects(s, @"135.35", nil);
}

@end
