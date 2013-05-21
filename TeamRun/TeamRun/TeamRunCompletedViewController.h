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
            seconds:(int)seconds
          teamMiles:(double)teamMiles
             logger:(TeamRunLogger*)logger
    facebookMessage:(NSString*)message;

@end
