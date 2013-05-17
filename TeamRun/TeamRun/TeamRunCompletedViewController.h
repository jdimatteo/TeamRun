//
//  TeamRunCompletedViewController.h
//  teamrun
//
//  Created by John DiMatteo on 5/2/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TeamRunLogger.h"

@interface TeamRunCompletedViewController : UIViewController

- (void)setMilesRan:(double)rawMiles
          inSeconds:(int)seconds
   withTeamMiles:(double)teamMiles
         withLogger:(id<TeamRunLogger>)logger;

@end
