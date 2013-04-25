//
//  TeamRunViewController.m
//  TeamRun
//
//  Created by John DiMatteo on 12/10/12.
//  Copyright (c) 2012 John DiMatteo. All rights reserved.
//

// pickup here: get accepting/sending invites working,
//              populate miles ahead label,
//              voice notifications (http://www.politepix.com/openears/tutorial -- use already downloaded plugin),
/* todo:
 
 don't use PSLocationManager directly -- instead use an abstract class, and have a Fake LocationManager available for testing that maintains a steady pace
 -- allow changing the pace via temporary test buttons (faster, slower -- no directly modifying distance)
 -- the fake can use a timer to send distance updates regularly, calculated from the last distance + (current pace * time since last distance)
 -- have a constant that determines whether or not the test buttons are visible and whether or not the fake location manager is used
 -- might want to call this the TeamRunModel and the location manager would just be part of it, and I could get rid of the silly singleton interface
 
 read up on good iOS design
 -- maybe I should have an explicit model (see above)? what is my controller (is it the storyboard)?
 -- how to have multiple storyboard elements where there is a main screen that leads to others and back to the main screen
 -- -- (maybe write a test app following a tutorial)
 -- automatic testing
 -- how users can report bugs (providing logs, stack trace, and/or a dump?), and how I can quickly diagnose/fix them
 
 design a good UI
 -- read up and experiment with colors and images
 -- learn how to use an image manipulation tool, or maybe find a collection of good stock images
 -- find a friend who is good at (iOS preferably) UI design and ask for advice
*/
 
#import "TeamRunViewController.h"
#import "PSLocationManager.h"

#import <GameKit/GameKit.h>

@interface TeamRunViewController ()
<GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate, PSLocationManagerDelegate>

- (IBAction)openGameCenter;
- (IBAction)startStopButtonClicked;

@property (weak, nonatomic) IBOutlet UITextView *scrollingText;
@property (weak, nonatomic) IBOutlet UILabel *timeRanLabel;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UILabel *currentPaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *averagePaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *milesRanLabel;

- (void)createMatch;
- (void)playerAuthenticated;
- (void)log:(NSString*)format,...;
- (void)secondRan:(NSTimer *)timer;

@property (weak, nonatomic) GKMatch* match;
@property (nonatomic) NSTimer* runningTimer;

@end

static const double MILES_PER_METER = 0.000621371;

@implementation TeamRunViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self authenticateLocalPlayer];
    [self log:@"Authenticating player..."];
    
    [PSLocationManager sharedLocationManager].delegate = self;
    [[PSLocationManager sharedLocationManager] prepLocationUpdates];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// todo: consider adding logInfo, logDebug, logError, etc.
- (void)log:(NSString *)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSLog(@"%@", message);
    [self.scrollingText setText:[NSString stringWithFormat:@"%@\n\n%@", [self.scrollingText text], message]];
    
    [self.scrollingText scrollRangeToVisible:NSMakeRange([self.scrollingText.text length], 0)];
}

- (IBAction)startStopButtonClicked {
    if (self.match != nil)
    {
        [self.match disconnect];
        self.match = nil;
        
        [self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
        
        [self.runningTimer invalidate];
        self.runningTimer = nil;
        
        [[PSLocationManager sharedLocationManager] stopLocationUpdates];
        [self log:@"takes ~10 seconds for GPS shutdown"];
    }
    else
    {
        [self createMatch];
    }
}

- (void)secondRan:(NSTimer *)timer
{
    int seconds = [PSLocationManager sharedLocationManager].totalSeconds;
    [self.timeRanLabel setText:[NSString stringWithFormat:@"%.2d:%.2d", seconds / 60, seconds % 60]];    
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   GameKit Related Methods
//
////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) authenticateLocalPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    __weak GKLocalPlayer *localPlayerRef = localPlayer;
    
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil)
        {
            [self presentViewController: viewController
                               animated: YES
                             completion: nil];
        }
        else if (localPlayerRef.authenticated)
        {
            [self playerAuthenticated];
        }
        else
        {
            [self log:@"Todo: better handle user authentication failure -- error: %@", error];
        }
    };
}

- (void)playerAuthenticated
{
    [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {
        // Insert game-specific code here to clean up any game in progress.
        
        [self log:@"invite handler called with acceptedInvite nil? %@, playersToInvite count: %d", acceptedInvite == nil, playersToInvite.count];
        
        if (acceptedInvite)
        {
            GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithInvite:acceptedInvite];
            mmvc.matchmakerDelegate = self;
            [self presentViewController:mmvc animated:YES completion:nil];
        }
        else if (playersToInvite)
        {
            GKMatchRequest *request = [[GKMatchRequest alloc] init];
            request.minPlayers = 2;
            request.maxPlayers = 4;
            request.playersToInvite = playersToInvite;
            
            GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
            mmvc.matchmakerDelegate = self;
            [self presentViewController:mmvc animated:YES completion:nil];
        }
    };
}

- (IBAction)openGameCenter {
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        [self presentViewController: gameCenterController animated: YES completion:nil];
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createMatch {
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 4;
    request.defaultNumberOfPlayers = 2;
    
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
    
    [self presentViewController:mmvc animated:YES completion:nil];
}

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self log:@"Match cancelled"];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self log:@"matchmaker failed with error: %@", error];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    match.delegate = self;
    self.match = match;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self log:@"Match found: %@", match];
    
    [[PSLocationManager sharedLocationManager] resetLocationUpdates];
    [[PSLocationManager sharedLocationManager] startLocationUpdates];
    
    self.runningTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(secondRan:)
                                                       userInfo:nil
                                                        repeats:YES];
    
    [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
}

- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
    [self log:@"match (%@) player (%@) did change state: %d\nexpected player count is now %d", match.description, playerID, state, match.expectedPlayerCount];
    switch (state)
    {
        case GKPlayerStateConnected:
            // Handle a new player connection.
            break;
        case GKPlayerStateDisconnected:
            // A player just disconnected.
            break;
    }
    // todo: consider not starting the match (the timer and gps) until match.expectedPlayerCount is 0
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    // todo: consider storing a struct with a message type and a double (if for nothing else than to make it future proof)
    double* distanceInMiles = (double*)[data bytes];
    [self log:@"player %@: %f miles", playerID, *distanceInMiles];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   GPS PSLocationManager Related Methods
//
////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)locationManager:(PSLocationManager *)locationManager signalStrengthChanged:(PSLocationManagerGPSSignalStrength)signalStrength {
    NSString *strengthText;
    if (signalStrength == PSLocationManagerGPSSignalStrengthWeak) {
        strengthText = @"weak";
    } else if (signalStrength == PSLocationManagerGPSSignalStrengthStrong) {
        strengthText = @"strong";
    } else {
        strengthText = @"...";
    }
    
    [self log:@"Signal strength changed to %@", strengthText];
}

- (void)locationManagerSignalConsistentlyWeak:(PSLocationManager *)locationManager {
    [self log:@"Signal strength consistently weak"];
}

- (void)locationManager:(PSLocationManager *)locationManager distanceUpdated:(CLLocationDistance)distance /* distance in meters */
{
    [self log:@"%.2f %@", distance, @"meters"];
    
    const double milesRan = distance*MILES_PER_METER;
    [self.milesRanLabel setText:[NSString stringWithFormat:@"%.2f", milesRan]];
    
    const double metersPerSecond = [PSLocationManager sharedLocationManager].currentSpeed;
    [self log:@"current speed: %f m/s", metersPerSecond];
    
    [self.currentPaceLabel setText:minutesPerMilePaceString(metersPerSecond)];
    
    [self.averagePaceLabel setText:minutesPerMilePaceString(distance/[PSLocationManager sharedLocationManager].totalSeconds)];
    
    NSError *error;
    // todo: change all stored distances to floats (I definately don't need the extra precision, and it doubles the amount of data transferred)
    NSData *packet = [NSData dataWithBytes:&milesRan length:sizeof(milesRan)];
    [self.match sendDataToAllPlayers: packet withDataMode: GKMatchSendDataReliable error:&error];
    if (error != nil)
    {
        [self log:@"error sending data to players: %@", error.description];
    }
}

- (void)locationManager:(PSLocationManager *)locationManager error:(NSError *)error {
    // location services is probably not enabled for the app
    [self log:@"Unable to determine location"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   Utility Methods
//
////////////////////////////////////////////////////////////////////////////////////////////////////


NSString* minutesPerMilePaceString(const double metersPerSecond)
{
    /* e.g. if currentSpeed = 1.95 (meters per second),
     *      then that is ~ 0.00121167345 miles per second (1.95 * MILES_PER_METER = 0.00121167),
     *      which is ~ 0.072700407 miles per minute (0.00121167345 * 60 = 0.072700407),
     *      which is ~ 13.7550811786 minutes per mile (1/0.072700407 = 13.7550811786),
     *      which is ~ 13:45 pace (minutes:second) per mile (.7550811786*60 = 45.304870716)
     *
     * it is easier to first get secondsPerMile pace, round that, and then
     * convert the rounded number to minutes per mile.
     *
     * e.g. 1.95 * MILES_PER_METER = 0.00121167 miles per second,
     *      1/0.00121167 = 825.307220613 seconds per mile,
     *      rounds to 825 seconds,
     *      floor(825/60) = 13 minutes,
     *      825 % 60 = 45 seconds,
     *      so the pace is 13:45 (minutes:seconds per mile)
     */
    
    const double milesPerSecond = metersPerSecond * MILES_PER_METER;
    
    if (milesPerSecond > 0) // prevent divide by zero errors
    {
        const int secondsPerMile = round(1.0 / milesPerSecond);
        
        const int paceMinutes = secondsPerMile / 60;
        const int paceSeconds = secondsPerMile % 60;
        
        if (paceMinutes > 59)
        {
            return @"0:00";
        }
        else
        {
            return [NSString stringWithFormat:@"%d:%02d", paceMinutes, paceSeconds];
        }
    }
    return @"0:00";
}


@end
