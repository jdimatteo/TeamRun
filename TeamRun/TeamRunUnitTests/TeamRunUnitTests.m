//
//  TeamRunUnitTests.m
//  TeamRunUnitTests
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
