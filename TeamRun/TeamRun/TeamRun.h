//
//  TeamRun.h -- class to represent a run -- the model for the TeamRunViewController
//  teamrun
//
//  Created by John DiMatteo on 5/23/13.
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

#import <GameKit/GameKit.h>

@interface TeamRun : NSObject

+ (void)startWarmingUpGPS; // it takes some time for the location to be initially accurately determined

- (id)init;                           // start single player match
- (id)initWithMatch:(GKMatch*)match;  // start multiplayer match (or single player if match is nil)
- (void)end;                          // end match

- (void)processData:(NSData*)data fromPlayer:(NSString*)playerID;


@property (nonatomic, readonly) bool      isMultiplayer;
@property (nonatomic, readonly) bool      isSinglePlayer;
@property (nonatomic, readonly) NSString* playerNames;
@property (nonatomic, readonly) double    meters;                 // distance ran
@property (nonatomic, readonly) double    miles;                  // distance ran
@property (nonatomic, readonly) double    targetMiles;            // miles ran if running at exactly the target mile pace
@property (nonatomic, readonly) double    milesOtherPlayerRan;    // based off last message received by other player
@property (nonatomic, readonly) double    seconds;                // seconds since run started
@property (nonatomic, readonly) double    averageMetersPerSecond; // average pace
@property (nonatomic, readonly) double    currentMetersPerSecond; // current pace

extern NSString * const NOTIF_RunStateChanged;

@end