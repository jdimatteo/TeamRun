//
//  TeamRun.m
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

#import "TeamRun.h"
#import "TeamRunLogger.h"
#import "TeamRunUtility.h"
#import "TeamRunSettings.h"

#import "PSLocationManager.h"

NSString * const NOTIF_RunStateChanged = @"TeamRunStateChanged";

typedef enum {PS, CL} SpeedCalcMethod;
static const SpeedCalcMethod speedCalcMethod = PS;

typedef struct
{
    float milesRan;
    int32_t secondsPerMileTargetPace; // <= 0 if no target pace set
} TeamRunMessageV1;

@interface TeamRun () <PSLocationManagerDelegate>
{
    TeamRunMessageV1 otherRunnerState;
}

@property (strong, nonatomic) GKMatch*    match;
@property (strong, nonatomic) NSArray*    players;
@property (strong, nonatomic) CLLocation* lastWayPoint;

- (void)notify;

@end

@implementation TeamRun

+ (void)startWarmingUpGPS
{
    [[PSLocationManager sharedLocationManager] prepLocationUpdates];
}

- (id)initWithMatch:(GKMatch *)match players:(NSArray*)players
{
    if ( (self = [super init]) == nil)
    {
        return nil;
    }
    
    self.match = match;
    self.players = players;

    // todo: are these automatically initialized to 0?  is this redundant?
    otherRunnerState.milesRan = 0;
    otherRunnerState.secondsPerMileTargetPace = 0;
    
    [[PSLocationManager sharedLocationManager] prepLocationUpdates]; // this does some initialization like clearing current speed history
    [PSLocationManager sharedLocationManager].delegate = self;
    [[PSLocationManager sharedLocationManager] resetLocationUpdates];
    [[PSLocationManager sharedLocationManager] startLocationUpdates];
        
    return self;
}

-(id)init
{
    return [self initWithMatch:nil players:nil];
}

- (void)processData:(NSData*)data fromPlayer:(NSString*)playerID
{
    if ([data length] == sizeof(TeamRunMessageV1))
    {
        otherRunnerState = *(TeamRunMessageV1*)[data bytes];
        LOG_DEBUG(@"player %@: %f miles (%d seconds target mile pace)", playerID, otherRunnerState.milesRan, otherRunnerState.secondsPerMileTargetPace);
        
        [self notify];
    }
    else
    {
        LOG_WARN(@"discarding unsupported message of length %d from player %@", [data length], playerID);
        //handle future message type sizes here
    }
}

- (void)end
{
    if (self.match != nil)
    {
        [self.match disconnect];
        self.match = nil;
    }
    
    self.players = nil;
    
    [[PSLocationManager sharedLocationManager] stopLocationUpdates];
    
    [PSLocationManager sharedLocationManager].delegate = nil;
    
    LOG_DEBUG(@"takes ~10 seconds for GPS shutdown");
}

- (double) seconds
{
    return [PSLocationManager sharedLocationManager].totalSeconds;
}

- (double) secondsRemaining
{
    const double secondsInRun = self.isMultiplayer ? 30*60 : INFINITY;

    return secondsInRun - self.seconds;
}

- (double) meters
{
    return [PSLocationManager sharedLocationManager].totalDistance;
}

- (double) targetMiles
{
    if ([TeamRunSettings targetSecondsPerMile] <= 0)
    {
        // prevent divide by zero error
        return 0;
    }
    
    return self.seconds / [TeamRunSettings targetSecondsPerMile];
}

- (double) miles
{
    return self.meters * MILES_PER_METER;
}

- (double) averageMetersPerSecond
{
    return self.meters/self.seconds;
}

- (double) currentMetersPerSecond
{
    if (speedCalcMethod == PS)
    {
        return [PSLocationManager sharedLocationManager].currentSpeed;
    }
    else //if (speedCalcMethod == CL)
    {
        return self.lastWayPoint == nil ? 0 : self.lastWayPoint.speed;
    }
}

- (bool)isMultiplayer
{
    return self.match != nil;
}

- (bool)isSinglePlayer
{
    return self.match == nil;
}

- (NSString*) playerNames
{
    NSMutableString *playerNames = [[NSMutableString alloc] init];
    
    if (self.isMultiplayer && self.players != nil)
    {
        for (int i=0; i < self.players.count; ++i)
        {
            if (i != 0) [playerNames appendString:@", "];
            
            if (self.players.count != 1 && i == self.players.count - 1) [playerNames appendString:@"and "];
            
            [playerNames appendString:[self.players[i] displayName]];
        }
    }
    return playerNames;
}

- (double) milesOtherPlayerRan
{
    double scalingFactor = 1.0;
    if (otherRunnerState.secondsPerMileTargetPace > 0 && [TeamRunSettings targetPaceEnabled] && [TeamRunSettings targetSecondsPerMile] > 0)
    {
        scalingFactor = otherRunnerState.secondsPerMileTargetPace / (double) [TeamRunSettings targetSecondsPerMile];
    }
    
    const double milesOtherPlayerRan = otherRunnerState.milesRan * scalingFactor;
    
    LOG_DEBUG(@"Updated milesOtherPlayerRan: %@ (scaling factor %@)", truncateToTwoDecimals(milesOtherPlayerRan), truncateToTwoDecimals(scalingFactor));
    
    return milesOtherPlayerRan;
}

- (double) milesAhead
{
    if (self.isSinglePlayer && [TeamRunSettings targetPaceEnabled] == NO) return 0;
    
    const double referenceMiles = self.isMultiplayer ? self.milesOtherPlayerRan : self.targetMiles;
    return self.miles - referenceMiles;
}

- (void)notify
{
    LOG_TRACE();
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_RunStateChanged object:nil];
    LOG_TRACE();
}

#pragma mark - GPS
////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   GPS PSLocationManager Related Methods
//
////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)locationManagerSignalConsistentlyWeak:(PSLocationManager *)locationManager {
    LOG_DEBUG(@"Signal strength consistently weak");
}


- (void)locationManager:(PSLocationManager *)locationManager signalStrengthChanged:(PSLocationManagerGPSSignalStrength)signalStrength {
    NSString *strengthText;
    if (signalStrength == PSLocationManagerGPSSignalStrengthWeak) {
        strengthText = @"weak";
    } else if (signalStrength == PSLocationManagerGPSSignalStrengthStrong) {
        strengthText = @"strong";
    } else {
        strengthText = @"...";
    }
    
    LOG_DEBUG(@"Signal strength changed to %@", strengthText);
}

- (void)locationManager:(PSLocationManager *)locationManager distanceUpdated:(CLLocationDistance)distance /* distance in meters */
{
    LOG_DEBUG(@"%f miles", self.miles);
     
    if (self.isMultiplayer)
    {
        TeamRunMessageV1 message;
        message.milesRan = self.miles;
        message.secondsPerMileTargetPace = [TeamRunSettings targetPaceEnabled] ? [TeamRunSettings targetSecondsPerMile] : -1;

        NSError *error;
        NSData *packet = [NSData dataWithBytes:&message length:sizeof(message)];
        
        [self.match sendDataToAllPlayers: packet withDataMode: GKMatchSendDataReliable error:&error];
        
        if (error != nil)
        {
            LOG_ERROR(@"error sending data to players: %@", error.description);
        }
    }
    
    [self notify];
}

- (void)locationManager:(PSLocationManager *)locationManager error:(NSError *)error {
    // location services is probably not enabled for the app
    LOG_ERROR(@"LocationManager error: %s", error);
}

- (void)locationManager:(PSLocationManager *)locationManager waypoint:(CLLocation *)waypoint calculatedSpeed:(double)calculatedSpeed
{
    LOG_DEBUG(@"Location Update %@:\n\tPS: %@\n\tCL: %@\n\tDelta:%f\n",
              truncateToTwoDecimals([PSLocationManager sharedLocationManager].totalSeconds),
              truncateToTwoDecimals(calculatedSpeed),
              truncateToTwoDecimals(waypoint.speed),
              calculatedSpeed - waypoint.speed
              );
    self.lastWayPoint = waypoint;

    [self notify];
}

@end
