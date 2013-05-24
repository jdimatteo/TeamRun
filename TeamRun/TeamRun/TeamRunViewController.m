//
//  TeamRunViewController.m
//  TeamRun
//
//  Created by John DiMatteo on 12/10/12.
//  Copyright (c) 2012 John DiMatteo. All rights reserved.
//

#import "TeamRunViewController.h"
#import "TeamRunUtility.h"
#import "TeamRunCompletedViewController.h"
#import "TeamRunSettings.h"
#import "TeamRunLogger.h"

#import "PSLocationManager.h"

#import <Awb/Awb.h>
#import <OpenEars/FliteController.h>
#import <OpenEars/AudioSessionManager.h>

#import <GameKit/GameKit.h>

#import <AudioToolbox/AudioSession.h>

@interface TeamRunViewController ()
<GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate, PSLocationManagerDelegate, UIActionSheetDelegate>

- (IBAction)startStopButtonClicked:(id)sender;
- (IBAction)openLeaderboards:(id)sender;

@property (weak, nonatomic) IBOutlet UITextView *scrollingText;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UILabel *currentPaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *averagePaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *milesRanLabel;
@property (weak, nonatomic) IBOutlet UILabel *milesAheadLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeDescriptionLabel;

- (void)createMatch;
- (void)startRun;
- (void)endRun;
- (void)updatePlayers;
- (void)playerAuthenticated;
- (void)secondRan:(NSTimer *)timer;
- (void)speakNotification:(NSTimer *)timer;
- (double)updateMilesAhead;
- (double)updateMilesAhead:(double) milesOtherPlayerRan targetSecondsPerMile:(int)secondsPerMileTargetPace;
- (void)updateNotificationsTimerIfNecessary;
- (NSString*) playerNames;

@property (strong, nonatomic) GKMatch* match;
@property (strong, nonatomic) NSArray* players;

@property (nonatomic) NSTimer* runningTimer;
@property (nonatomic) NSTimer* paceUpdateTimer;

@end

// gps could be off by 20 meters, so if there are two of them a difference of less than 40 meters
// could just be noise.  40 meters is about .0249 miles, so don't report any difference less than .025 miles
static const double ON_PACE_THRESHOLD_MILES = 0.025;

typedef enum {PS, CL} SpeedCalcMethod;
static const SpeedCalcMethod speedCalcMethod = CL;

typedef struct
{
    float milesRan;
    int32_t secondsPerMileTargetPace; // <= 0 if no target pace set
} TeamRunMessageV1;

FliteController *fliteController;
Awb *voice;

dispatch_queue_t speachQueue;

bool runInProgress;

@implementation TeamRunViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [TeamRunLogger setScrollingLogText:self.scrollingText];
    
    [self authenticateLocalPlayer];
    LOG_INFO(@"Authenticating player...");
            
    [PSLocationManager sharedLocationManager].delegate = self;
    [[PSLocationManager sharedLocationManager] prepLocationUpdates];
    
    // following causes open ears speach to work while running in the background or locked
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AudioSessionManager sharedAudioSessionManager]setSoundMixing:YES];
    
    speachQueue = dispatch_queue_create("org.TeamRun.SpeachQueue", NULL);
    
    self.scrollingText.hidden = true; // hide unless needed for debugging
    
    runInProgress = false;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateNotificationsTimerIfNecessary];
}

- (void)updateNotificationsTimerIfNecessary
{
    bool notifications = [TeamRunSettings notificationsEnabled] && runInProgress;
    
    if (self.paceUpdateTimer != nil)
    {
        if (!notifications || [self.paceUpdateTimer timeInterval] != [TeamRunSettings secondsBetweenNotifications])
        {
            [self.paceUpdateTimer invalidate];
            self.paceUpdateTimer = nil;
        }
    }
    
    if (notifications && self.paceUpdateTimer == nil)
    {
        self.paceUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:[TeamRunSettings secondsBetweenNotifications]
                                                                target:self
                                                              selector:@selector(speakNotification:)
                                                              userInfo:nil
                                                               repeats:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        // End Run confirmation button tapped
        [self endRun];
    }
}

- (IBAction)startStopButtonClicked:(id)sender
{
    if (runInProgress)
    {
        NSString *message = @"Are you sure you want to end your run?";
        
        NSString *playerNames = [self playerNames];
        
        if (playerNames.length > 0)
        {
            const int remainingMinutes = (30*60 - round([PSLocationManager sharedLocationManager].totalSeconds))/60;
            
            message = [NSString stringWithFormat:@"%@\n\nThere are %d minutes remaining in your run with %@.", message, remainingMinutes, playerNames];
        }
        
        UIActionSheet *endRunConfirmationPrompt = [[UIActionSheet alloc] initWithTitle:message delegate:self cancelButtonTitle:@"Keep Running" destructiveButtonTitle:@"End Run" otherButtonTitles:nil];
        
        endRunConfirmationPrompt.actionSheetStyle = UIBarStyleBlackOpaque;
        [endRunConfirmationPrompt showInView:self.view];
    }
    else
    {
        if ([TeamRunSettings multiplayerMode])
        {
            [self createMatch];
        }
        else
        {
            [self startRun];
        }
    }
}

- (void)secondRan:(NSTimer *)timer
{
    if (self.match == nil)
    {
        const int secondsRan = round([PSLocationManager sharedLocationManager].totalSeconds);
        [self.timeLabel setText:[NSString stringWithFormat:@"%d:%02d", secondsRan / 60, secondsRan % 60]];
    }
    else
    {
        // all multiplayer runs are 30 minutes long
        const int remainingSeconds = 30*60 - round([PSLocationManager sharedLocationManager].totalSeconds);
        
        if (remainingSeconds <= 0)
        {
            [self endRun];
        }
        else
        {
            [self.timeLabel setText:[NSString stringWithFormat:@"%d:%02d", remainingSeconds / 60, remainingSeconds % 60]];
        }
    }
    [self updateMilesAhead];
}

- (void)speakNotification:(NSTimer *)timer
{
    const int secondsRan = [PSLocationManager sharedLocationManager].totalSeconds;
    NSString* durationRan = secondsRan >= 60 ? [NSString stringWithFormat:@"%d minutes %d seconds", secondsRan/60, secondsRan % 60]
                                             : [NSString stringWithFormat:@"%d seconds", secondsRan];
        
    NSString* pace = minutesPerMilePaceString([PSLocationManager sharedLocationManager].totalDistance/[PSLocationManager sharedLocationManager].totalSeconds, true);
    
    NSString* paceNotification = [NSString stringWithFormat:@"You have run %@, %@ miles, at %@ mile pace.", durationRan, self.milesRanLabel.text, pace];
    
    const double milesAhead = [self updateMilesAhead];
    
    NSString* relativePositionNotification = absoluteValue(milesAhead) > ON_PACE_THRESHOLD_MILES
        ? [NSString stringWithFormat:@"You are about %@ miles %@.", truncateToTwoDecimals(absoluteValue(milesAhead)), milesAhead >= 0 ? @"ahead" : @"behind"]
        : @"You are on pace";
    
    NSString* notification = [NSString stringWithFormat:@"%@ %@",
                              [TeamRunSettings paceNotificationsEnabled] ? paceNotification : @"",
                              [TeamRunSettings relativePositionNotificationsEnabled] ? relativePositionNotification : @""];
    [self say:notification];
}

- (double)updateMilesAhead
{
    return [self updateMilesAhead:-1 targetSecondsPerMile:-1];
}

// todo: this probably isn't good style -- maybe make this an optional arg or overload the function?
// pass in -1 for distance if it is unchanged
// pass in 0 (or less) for secondsPerMileTargetPace if no mile target pace set
// returns milesAhead of other runner
- (double)updateMilesAhead:(double) milesOtherPlayerRan targetSecondsPerMile:(int)secondsPerMileTargetPace
{
    static double lastRecordedMilesOtherPlayerRan = 0;
    
    if (milesOtherPlayerRan == -1.0)
    {
        milesOtherPlayerRan = lastRecordedMilesOtherPlayerRan;
    }
    else
    {
        double scalingFactor = 1.0;
        if (secondsPerMileTargetPace > 0 && [TeamRunSettings targetPaceEnabled] && [TeamRunSettings targetSecondsPerMile] > 0)
        {
            scalingFactor = secondsPerMileTargetPace / (double) [TeamRunSettings targetSecondsPerMile];
        }
        milesOtherPlayerRan = milesOtherPlayerRan * scalingFactor;
        lastRecordedMilesOtherPlayerRan = milesOtherPlayerRan;
        LOG_DEBUG(@"Updated lastRecordedMilesOtherPlayerRan: %@ (scaling factor %@)", truncateToTwoDecimals(lastRecordedMilesOtherPlayerRan), truncateToTwoDecimals(scalingFactor));
    }
    
    /* todo: consider setting ahead / behind colors 
    static UIColor* darkGreen = nil;
    static UIColor* darkRed = nil;
    if (darkGreen == nil || darkRed == nil)
    {
        darkGreen = [UIColor colorWithRed:0.1015625 green:0.3984375 blue:0.125 alpha:1];
        darkRed = [UIColor colorWithRed:0.75 green:0 blue:0 alpha:1];
    }*/

    const double milesRan = [PSLocationManager sharedLocationManager].totalDistance * MILES_PER_METER;
    
    const double targetMilesRanIfRunningAtTargetMilePace = ([TeamRunSettings targetSecondsPerMile] > 0) ?[PSLocationManager sharedLocationManager].totalSeconds / [TeamRunSettings targetSecondsPerMile] : 0;
    
    LOG_DEBUG(@"targetMilesRanIfRunningAtTargetMilePace = %@, seconds: %d, target seconds per mile: %d", truncateToTwoDecimals(targetMilesRanIfRunningAtTargetMilePace), (int) [PSLocationManager sharedLocationManager].totalSeconds, [TeamRunSettings targetSecondsPerMile]);
    
    const double referenceMiles = (self.match != nil) ? milesOtherPlayerRan : targetMilesRanIfRunningAtTargetMilePace;
    
    [self.milesAheadLabel setHidden:(self.match == nil && ![TeamRunSettings targetPaceEnabled])];
    
    double milesAhead = milesRan - referenceMiles;
    if ( absoluteValue(milesAhead) < ON_PACE_THRESHOLD_MILES)
    {
        [self.milesAheadLabel setText:@"on pace"];
    }
    else
    {
        NSString* aheadOrBehind;

        if (milesRan >= referenceMiles)
        {
            aheadOrBehind = @"ahead";
            //[self.milesAheadLabel setTextColor:darkGreen];
        }
        else
        {
            aheadOrBehind = @"behind";
            //[self.milesAheadLabel setTextColor:darkRed];
        }
        [self.milesAheadLabel setText:[NSString stringWithFormat:@"%@ mi %@", truncateToTwoDecimals(absoluteValue(milesAhead)), aheadOrBehind]];
    }
    
    return milesAhead;
}

#pragma mark - GameKit
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
            LOG_ERROR(@"Todo: better handle user authentication failure -- error: %@", error);
        }
    };
}

- (void)playerAuthenticated
{
    [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {
        // Insert game-specific code here to clean up any game in progress.
        
        LOG_INFO(@"invite handler called with acceptedInvite nil? %@, playersToInvite count: %d", acceptedInvite == nil, playersToInvite.count);
        
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
            request.maxPlayers = 2;
            request.playersToInvite = playersToInvite;
            
            GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
            mmvc.matchmakerDelegate = self;
            [self presentViewController:mmvc animated:YES completion:nil];
        }
    };
}

- (IBAction)openLeaderboards:(id)sender
{
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
    // todo: remove duplicate code from here and invite handler
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    request.defaultNumberOfPlayers = 2;
    
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
    
    [self presentViewController:mmvc animated:YES completion:nil];
}

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    LOG_DEBUG(@"Match cancelled");
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    LOG_ERROR(@"matchmaker failed with error: %@", error);
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    match.delegate = self;
    self.match = match;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    LOG_DEBUG(@"Match found -- expectedPlayerCount: %d", match.expectedPlayerCount);
    
    if (runInProgress) LOG_ERROR(@"runInProgress should be false if didFindMatch called");
    
    if (!runInProgress && match.expectedPlayerCount == 0)
    {
        [self startRun];
    }
}

- (void)startRun
{
    runInProgress = true;
    
    [[PSLocationManager sharedLocationManager] resetLocationUpdates];
    [[PSLocationManager sharedLocationManager] startLocationUpdates];
    
    [self updateMilesAhead:0 targetSecondsPerMile:-1];
    
    self.runningTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(secondRan:)
                                                       userInfo:nil
                                                        repeats:YES];
    
    [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
    
    [self updateNotificationsTimerIfNecessary];
    
    [self updatePlayers];
    
    [self.timeDescriptionLabel setText:(self.match == nil ? @"time ran" : @"time remaining")];
    [self secondRan:nil];
}

- (void)endRun
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    TeamRunCompletedViewController *completionViewController = [storyboard instantiateViewControllerWithIdentifier:@"RunCompletedViewController"];
    
    {
        // todo: we should probably just be passing a run object here
        
        const double rawMiles = [PSLocationManager sharedLocationManager].totalDistance*MILES_PER_METER;
        const double teamRunMiles = self.match == nil ? rawMiles
                                                      : 2*(rawMiles + [self updateMilesAhead]);
        
        NSString* withMessage = @"";
        NSString* playerNames = [self playerNames];
        if (playerNames.length > 0 )
        {
            withMessage = [NSString stringWithFormat:@" with %@", playerNames];
        }
        
        NSString* facebookMessage = [NSString stringWithFormat:@"I completed a %@ mile run%@", truncateToTwoDecimals(rawMiles), withMessage];

        [self presentViewController:completionViewController animated:YES completion:nil];
        
        [completionViewController setMilesRan:rawMiles
                                      seconds:[PSLocationManager sharedLocationManager].totalSeconds
                                    teamMiles:teamRunMiles
                              facebookMessage:facebookMessage];
    }
    
    runInProgress = false;

    if (self.match != nil)
    {
        [self.match disconnect];
        self.match = nil;
    }
    
    self.players = nil;
    
    [self.startStopButton setTitle:@"Run" forState:UIControlStateNormal];
    
    [self.runningTimer invalidate];
    self.runningTimer = nil;
    
    [self updateNotificationsTimerIfNecessary];
    
    [[PSLocationManager sharedLocationManager] stopLocationUpdates];
    LOG_DEBUG(@"takes ~10 seconds for GPS shutdown");
}

- (void)updatePlayers
{
    if (self.match != nil)
    {
        [GKPlayer loadPlayersForIdentifiers:self.match.playerIDs withCompletionHandler:^(NSArray *players, NSError *error)
        {
            LOG_DEBUG(@"loadPlayersForIdentifiers completion handler called");
            if (error != nil)
            {
                LOG_ERROR(@"Error loading player information: %@", error);
                
                // todo: consider retrying to get players
            }
            
            self.players = players;
            LOG_DEBUG(@"players set: %@", self.players);
        }];
    }
    else
    {
        self.players = nil;
    }
}

- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
    switch (state)
    {
        case GKPlayerStateConnected:
            LOG_INFO(@"player (%@) connected (%d\nexpected player count is now %d)", playerID, match.expectedPlayerCount);
            break;
        case GKPlayerStateDisconnected:
            LOG_WARN(@"player (%@) disconnected (%d\nexpected player count is now %d)", playerID, match.expectedPlayerCount);
            break;
        default:
            LOG_ERROR(@"match (%@) player (%@) unrecognized state (%d), expected player count is now %d", match.description, playerID, state, match.expectedPlayerCount);
    }
    
    if (!runInProgress && match.expectedPlayerCount == 0)
    {
        [self startRun];
    }
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    if ([data length] == sizeof(TeamRunMessageV1))
    {
        TeamRunMessageV1* message = (TeamRunMessageV1*)[data bytes];
        
        LOG_DEBUG(@"player %@: %f miles (%d seconds target mile pace)", playerID, message->milesRan, message->secondsPerMileTargetPace);
        
        [self updateMilesAhead:message->milesRan targetSecondsPerMile:message->secondsPerMileTargetPace];
    }
    else
    {
        LOG_WARN(@"discarding unsupported message of length %d from player %@", [data length], playerID);
    }
    // else -- handle future message type sizes
}

#pragma mark - GPS
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
    
    LOG_DEBUG(@"Signal strength changed to %@", strengthText);
}

- (void)locationManagerSignalConsistentlyWeak:(PSLocationManager *)locationManager {
    LOG_DEBUG(@"Signal strength consistently weak");
}

- (void)locationManager:(PSLocationManager *)locationManager distanceUpdated:(CLLocationDistance)distance /* distance in meters */
{    
    const float milesRan = distance*MILES_PER_METER;
    [self.milesRanLabel setText:truncateToTwoDecimals(milesRan)];
    LOG_DEBUG(@"%f miles", milesRan);
    
    if (self.match != nil)
    {
        TeamRunMessageV1 message;
        message.milesRan = milesRan;
        message.secondsPerMileTargetPace = [TeamRunSettings targetPaceEnabled] ? [TeamRunSettings targetSecondsPerMile] : -1;
        
        NSError *error;
        // todo: change all stored distances to floats (I definately don't need the extra precision, and it doubles the amount of data transferred)
        NSData *packet = [NSData dataWithBytes:&message length:sizeof(message)];
        [self.match sendDataToAllPlayers: packet withDataMode: GKMatchSendDataReliable error:&error];
        if (error != nil)
        {
            LOG_ERROR(@"error sending data to players: %@", error.description);
        }
    }
    
    [self updateMilesAhead];
}

- (void)locationManager:(PSLocationManager *)locationManager waypoint:(CLLocation *)waypoint calculatedSpeed:(double)calculatedSpeed
{
    if (runInProgress)
    {
        LOG_DEBUG(@"Location Update %@:\n\tPS: %@\n\tCL: %@\n\tDelta:%f\n",
         truncateToTwoDecimals([PSLocationManager sharedLocationManager].totalSeconds),
         truncateToTwoDecimals(calculatedSpeed),
         truncateToTwoDecimals(waypoint.speed),
         calculatedSpeed - waypoint.speed
         );
        
        if (speedCalcMethod == PS)
        {
            const double metersPerSecond = [PSLocationManager sharedLocationManager].currentSpeed;
            
            [self.currentPaceLabel setText:minutesPerMilePaceString(metersPerSecond, false)];        
        }
        else if (speedCalcMethod == CL)
        {        
            [self.currentPaceLabel setText:minutesPerMilePaceString(waypoint.speed, false)];
        }
        
        [self.averagePaceLabel setText:minutesPerMilePaceString([PSLocationManager sharedLocationManager].totalDistance/[PSLocationManager sharedLocationManager].totalSeconds, false)];
    }
}

- (void)locationManager:(PSLocationManager *)locationManager error:(NSError *)error {
    // location services is probably not enabled for the app
    LOG_ERROR(@"LocationManager error: %s", error);
}

#pragma mark - OpenEars
////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   OpenEars Methods
//
////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) say:(NSString*)textToSay
{
    LOG_DEBUG(@"say %@", textToSay);
    if (voice == nil) {
		voice = [[Awb alloc] init];
	}
    
    if (fliteController == nil) {
		fliteController = [[FliteController alloc] init];
	}
    
    // creating the audio from text takes a second or two to create (before it starts playing),
    // and this noticibly ties up the main thread preventing user interaction (e.g. buttons don't respond to taps),
    // so we execute this asynchronously
    dispatch_async(speachQueue, ^{ [fliteController say:textToSay withVoice:voice]; });    
}

#pragma mark - Utility
////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   Utility Methods
//
////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString*) playerNames
{
    NSMutableString *playerNames = [[NSMutableString alloc] init];

    if (self.match != nil && self.players != nil)
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

@end
