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

- (void)testTruncateToTwoDecimals
{
    STAssertEqualObjects(truncateToTwoDecimals(0.35), @"0.35", nil);
    
    STAssertEqualObjects(truncateToTwoDecimals(0.354), @"0.35", nil);
    
    STAssertEqualObjects(truncateToTwoDecimals(0.356), @"0.35", nil);

    STAssertEqualObjects(truncateToTwoDecimals(135.359), @"135.35", nil);
}

@end
