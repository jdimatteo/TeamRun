//
//  TeamRunCompletedViewController.h
//  teamrun
//
//  Created by John DiMatteo on 5/2/13.
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

#import <UIKit/UIKit.h>

#import "TeamRunLogger.h"

@interface TeamRunCompletedViewController : UIViewController

- (void)setMilesRan:(double)rawMiles
            seconds:(int)seconds
          teamMiles:(double)teamMiles
    facebookMessage:(NSString*)message;

@end
