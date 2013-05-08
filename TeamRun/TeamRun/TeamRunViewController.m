//
//  TeamRunViewController.m
//  TeamRun
//
//  Created by John DiMatteo on 12/10/12.
//  Copyright (c) 2012 John DiMatteo. All rights reserved.
//

/* pickup here: current pace fluctautes too wildly,
                speak pace based on setting duration,
                implement rest of behavior based on settings,
                make spoken text easy to understand when background music is playing,

UI Design:
 
 note: I experimented with a Tab Bar Controller, and using Toolbars, but I don't think either fit with my buttons and views
       (e.g. tabs don't work because leaderboards is not a tab, and toolbar isn't supposed to be used to change views).
       I also tried implementing the settings screen as a table view, but the scrolling seemed unnecessary and it didn't
       look good either.  I also tried setting the background to an empty table view, but that also looked poor.
       The settings and main screen are good enough as is, stop fiddling!
 
 handle dropping/re-adding players

 login not possible after you click the start button
   
 design how more than 2 runners will work, and permit 2-4 players
 
 make the settings screen have sections like the settings app, and maybe the pin stripes texture
  
 "Target Pace" might be misleading
 
 find a good name -- TeamRun, KeepPace, RunBuddy, ...
 
 make a better app icon
 
 end of run screen
 
Required before initial release:
 
 get accepting/sending invites working
 
 facebook sharing (optionally including the names of everyone ran with, maybe using Facebook tagging or something)
 - include a nice icon which when clicked is a link to buy the game
  
todo:
 
 include passing/delta ahead notification settings (on unconnected view controller)
 
 1 and .09 miles sounds bad
 
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
 
 synchronize distance/times between players
 -- if I just send distances and there is a couple second delay, then two runners running side by side will both report being ahead of each other
 
 instead of radio mode, maybe record 2 sayings (one for faster, and one for slower), so recording can be sent just once,
 which would eliminate most data transfer needs (just send a couple bytes instead of an audio recording)
    
 better voices
 -- try having one voice for positive notifications and another voice for negative notifications
    or maybe just one voice that is better than Slt
 -- https://bitbucket.org/Politepix/openearsextras
  
 design an automated application level test (e.g. to confirm that settings are saved properly)
 
 twitter sharing
 
 test that screen resizes properly when phone call green bar is at top of screen of iPhone 4 
 
 test that starting a second run works properly (e.g. GPS starts back up properly, fields display new run info, average pace is reset, etc.)
 
 Additional Features (maybe version 2)
 
 - Announce Ahead/Behind changed by X meters setting
 - Announce passing setting
 */
 
#import "TeamRunViewController.h"
#import "TeamRunUtility.h"
#import "TeamRunCompletedViewController.h"
#import "TeamRunSettings.h"

#import "PSLocationManager.h"

#import <Slt/Slt.h>
#import <OpenEars/FliteController.h>
#import <OpenEars/AudioSessionManager.h>

#import <GameKit/GameKit.h>

@interface TeamRunViewController ()
<GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate, PSLocationManagerDelegate>

- (IBAction)startStopButtonClicked:(id)sender;
- (IBAction)openLeaderboards:(id)sender;

@property (weak, nonatomic) IBOutlet UITextView *scrollingText;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainingLabel;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UILabel *currentPaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *averagePaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *milesRanLabel;
@property (weak, nonatomic) IBOutlet UILabel *milesAheadLabel;

- (void)createMatch;
- (void)endMatch;
- (void)playerAuthenticated;
- (void)log:(NSString*)format,...;
- (void)secondRan:(NSTimer *)timer;
- (void)speakNotification:(NSTimer *)timer;
- (void)updateMilesAhead:(double) milesOtherPlayerRan;
- (void)updateNotificationsTimerIfNecessary;

@property (weak, nonatomic) GKMatch* match;
@property (nonatomic) NSTimer* runningTimer;
@property (nonatomic) NSTimer* paceUpdateTimer;

@property (strong, nonatomic) FliteController *fliteController;
@property (strong, nonatomic) Slt *slt;

@end

static const double MILES_PER_METER = 0.000621371;

FliteController *fliteController;
Slt *slt;

@implementation TeamRunViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self authenticateLocalPlayer];
    [self log:@"Authenticating player..."];
    
    [PSLocationManager sharedLocationManager].delegate = self;
    [[PSLocationManager sharedLocationManager] prepLocationUpdates];
    
    // following causes open ears speach to work while running in the background or locked
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AudioSessionManager sharedAudioSessionManager]setSoundMixing:YES];    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateNotificationsTimerIfNecessary];
}

- (void)updateNotificationsTimerIfNecessary
{
    bool notifications = [TeamRunSettings notificationsEnabled] && self.match != nil;
    
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

- (IBAction)startStopButtonClicked:(id)sender
{
    if (self.match != nil)
    {
        [self endMatch];
    }
    else
    {
        [self createMatch];
    }
}

- (void)secondRan:(NSTimer *)timer
{
    // all runs are 30 minutes long
    int remainingSeconds = 30*60 - [PSLocationManager sharedLocationManager].totalSeconds;
    
    if (remainingSeconds <= 0)
    {
        [self endMatch];
    }
    else
    {
        [self.timeRemainingLabel setText:[NSString stringWithFormat:@"%.2d:%.2d", remainingSeconds / 60, remainingSeconds % 60]];
    }
}

- (void)speakNotification:(NSTimer *)timer
{
    NSString* textToSay = [NSString stringWithFormat:@"Average pace is %@", self.averagePaceLabel.text];
    [self log:@"About to say: %@", textToSay];
    [self.fliteController say:textToSay withVoice:self.slt];
}

// todo: this probably isn't good style -- maybe make this an optional arg or overload the function?
// pass in -1 for distance if it is unchanged
- (void)updateMilesAhead:(double) milesOtherPlayerRan
{
    static double lastRecordedMilesOtherPlayerRan = 0;
    
    if (milesOtherPlayerRan == -1.0)
    {
        milesOtherPlayerRan = lastRecordedMilesOtherPlayerRan;
    }
    else
    {
        lastRecordedMilesOtherPlayerRan = milesOtherPlayerRan;
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

    double milesAheadOfOtherRunner = milesRan - (milesOtherPlayerRan);
    if ( (milesAheadOfOtherRunner < 0 ? -1.0 * milesAheadOfOtherRunner : milesAheadOfOtherRunner ) < 0.25)
    {
        // gps could be off by 20 meters, so if there are two of them a difference of less than 40 meters
        // could just be noise.  40 meters is about .249 miles, so don't report any difference less than .25 miles
        [self.milesAheadLabel setText:@"on pace"];
    }
    else
    {
        NSString* aheadOrBehind;

        if (milesRan >= milesOtherPlayerRan)
        {
            aheadOrBehind = @"ahead";
            //[self.milesAheadLabel setTextColor:darkGreen];
        }
        else
        {
            milesAheadOfOtherRunner *= -1;
            aheadOrBehind = @"behind";
            //[self.milesAheadLabel setTextColor:darkRed];
        }
        [self.milesAheadLabel setText:[NSString stringWithFormat:@"%@ mi %@", truncateToTwoDecimals(milesAheadOfOtherRunner), aheadOrBehind]];
    }
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
    [self log:@"Match found"];
    
    [[PSLocationManager sharedLocationManager] resetLocationUpdates];
    [[PSLocationManager sharedLocationManager] startLocationUpdates];
    
    [self updateMilesAhead:0];
    
    self.runningTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(secondRan:)
                                                       userInfo:nil
                                                        repeats:YES];
    
    [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
    
    [self updateNotificationsTimerIfNecessary];
}

- (void)endMatch
{
    [self.match disconnect];
    self.match = nil;
    
    [self.startStopButton setTitle:@"Run" forState:UIControlStateNormal];
    
    [self.runningTimer invalidate];
    self.runningTimer = nil;
    
    [self updateNotificationsTimerIfNecessary];
    
    [[PSLocationManager sharedLocationManager] stopLocationUpdates];
    [self log:@"takes ~10 seconds for GPS shutdown"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    TeamRunCompletedViewController *completionViewController = [storyboard instantiateViewControllerWithIdentifier:@"RunCompletedViewController"];
    [self presentViewController:completionViewController animated:YES completion:nil];
}

- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
    switch (state)
    {
        case GKPlayerStateConnected:
            [self log:@"player (%@) connected (%d\nexpected player count is now %d)", playerID, match.expectedPlayerCount];
            break;
        case GKPlayerStateDisconnected:
            [self log:@"player (%@) disconnected (%d\nexpected player count is now %d)", playerID, match.expectedPlayerCount];
            break;
        default:
            [self log:@"match (%@) player (%@) unrecognized state (%d), nexpected player count is now %d", match.description, playerID, state, match.expectedPlayerCount];
    }
    // todo: consider not starting the match (the timer and gps) until match.expectedPlayerCount is 0
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    // todo: consider storing a struct with a message type and a double (if for nothing else than to make it future proof)
    double* milesOtherPlayerRan = (double*)[data bytes];
    [self log:@"player %@: %f miles", playerID, *milesOtherPlayerRan];
    
    [self updateMilesAhead:*milesOtherPlayerRan];
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
    const double milesRan = distance*MILES_PER_METER;
    [self.milesRanLabel setText:truncateToTwoDecimals(milesRan)];
    [self log:@"%f miles", milesRan];
    
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
    
    [self updateMilesAhead:-1];
    
    NSString* textToSay = [NSString stringWithFormat:@"%@ miles ran", [self speachStringFromDecimal: milesRan]];
    [self.fliteController say:textToSay withVoice:self.slt];
}

- (void)locationManager:(PSLocationManager *)locationManager error:(NSError *)error {
    // location services is probably not enabled for the app
    [self log:@"Unable to determine location"];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   OpenEars Methods
//
////////////////////////////////////////////////////////////////////////////////////////////////////

- (FliteController *)fliteController {
	if (fliteController == nil) {
		fliteController = [[FliteController alloc] init];
	}
	return fliteController;
}

- (Slt *)slt {
	if (slt == nil) {
		slt = [[Slt alloc] init];
	}
	return slt;
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

// open ears pernounces a blip after the point when saying strings like "1.03" but not strings like "1 and .03",
// so this function formats strings to not pernounce the blip (this is working around a bug in open ears)
-(NSString*) speachStringFromDecimal:(const double) value
{
    // test case I tried, all sounded fine:
    //[self.fliteController say:[NSString stringWithFormat:@"%@ miles ran", [self speachStringFromDecimal:0.03]] withVoice:self.slt];
    //[self.fliteController say:[NSString stringWithFormat:@"%@ miles ran", [self speachStringFromDecimal:1.00]] withVoice:self.slt];
    //[self.fliteController say:[NSString stringWithFormat:@"%@ miles ran", [self speachStringFromDecimal:1.00723]] withVoice:self.slt];
    //[self.fliteController say:[NSString stringWithFormat:@"%@ miles ran", [self speachStringFromDecimal:0.00]] withVoice:self.slt];
    //[self.fliteController say:[NSString stringWithFormat:@"%@ miles ran", [self speachStringFromDecimal:0.0077]] withVoice:self.slt];
    //[self.fliteController say:[NSString stringWithFormat:@"%@ miles ran", [self speachStringFromDecimal:1.03]] withVoice:self.slt];
    
    const int integer = value;
    const int hundreths = (value - integer)*100;
    if (integer == 0 && hundreths == 0)
    {
        return @".00";
    }
    else if (integer == 0 && hundreths != 0)
    {
        return [NSString stringWithFormat:@".%02d", hundreths];
    }
    else
    {
        return [NSString stringWithFormat:@"%d and .%02d", integer, hundreths];
    }
}

@end
