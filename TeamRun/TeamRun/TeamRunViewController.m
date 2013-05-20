//
//  TeamRunViewController.m
//  TeamRun
//
//  Created by John DiMatteo on 12/10/12.
//  Copyright (c) 2012 John DiMatteo. All rights reserved.
//

/* pickup here: customize ahead label for single and multiplayer mode (say ahead of target pace, or ahead of Molly and make two lines),
                some way to see information about other player: e.g. their display name, and their target pace,
                some way to communicate with other player especially before timer starts (maybe a chat room that can be re-opened by swiping to the side?),
 
   next time running with two phones:
        -- have Sarah's phone use speedCalcMethod = PS and my phone use speedCalcMethod = CL, and compare smoothness, and responsiveness to sprinting and stopping
        -- test/implement total team miles calculation/reporting/display
  
 rename app from "Team Run" to "TeamRun", add screenshots, move my game to a game group, so that leaderboards can be shared if I make a paid version, and update description to be the following:
 
 - first and only multiplayer running game to keep pace with friends running real time in remote locations
 - social element to motivate exercise: studies show running with a friend increases miles ran by 53% and calories burned by 66%
 - scale paces so runners of different abilities can still motivate each other to maintain a target pace
 - configurable audio pace and relative position notifications while you run
 - track distance ran and pace, with personal bests recorded, and leaderboards to compete with other runners
 - team miles: the more people you run with, the more team miles you earn
 - global weekly Sunday TeamRun at 11 AM eastern standard time
 - full featured and completely free with no ads
 
Proably required before initial release:
 
 hard to reproduce bug: speaking notifications continues after run stopped (maybe one extra sometimes?)
 -- this just happened again when the notifications were set to occur every second, and I stopped the run after like 30 seconds, and multiple spoken notifications continued after the run had stopped -- do the spoken notifications go into a queue and fall behind?
 
 test when user not logged into Facebook on app -- it looks like it just silently fails to post, but it should prompt user to login
 
 test when a user drops out of a match -- for example, there seems to be a bug where if John and Sarah are running together and Sarah drops out, then John is still warned about Sarah running if John tries to cancel early -- we need better behavior and notification, I guess converting to a single player run
 
 verify that time ran shows hours correctly (e.g. it shouldn't show > 60 minutes)
 
 test audio behavior when a phone call occurs during game play
          
 test that screen resizes properly when phone call green bar is at top of screen of iPhone 4
 
 test that starting a second run works properly (e.g. GPS starts back up properly, fields display new run info, average pace is reset, etc.)
 
 review all inline todos in every file
 
 review logs for errors about contraints not being met and fix this
 
UI Design (probably good to cover all these items before initial release):
 
 display gps accuracy
 
 display some sort of notification to user if match making error occurred (e.g. if not connected to internet, automatch will time out)
 
 settings
 -- on the settings screen, add a ? button (or some other info button) that explains the settings
 
 when tapping a number field on the settings screen, highlight what is already selected so that it can be overwritten without deleting
 
 handle dropping/re-adding players (test if this ever occurs... hopefully GameCenter is fairly lenient with regards to poor network)
  
 "Target Pace" might be misleading
  
 add icons for the high scores (this can be done after game published)
 
Additional Todos (maybe version 2)
 
 hard to reproduce bug?  audio from pandora stops when switching to team run game
 
 better facebook sharing (optionally including the names of everyone ran with, maybe using Facebook tagging or something)
 - include a nice icon which when clicked is a link to buy the game
 
 preface log messages with their level (e.g. ERROR:)
 
 walkie talkie like communication, or maybe just record 2 sayings (one for faster, and one for slower), so recording can be sent just once,
 which would eliminate most data transfer needs (just send a couple bytes instead of an audio recording)
 
 - twitter sharing
 - cache best and total score per player per category in case best/total score can't be found or is outdated,
 - make logger a concrete class, and move the logging definitions there
 - design how more than 2 runners will work, and permit 2-4 players
 - Announce Ahead/Behind changed by X meters setting
 - Announce passing setting
 - reverse radar like noise so that it increases frequency when ahead or behind
 - experiment with blue color and talk to a designer
 
 - don't use PSLocationManager directly -- instead use an abstract class, and have a Fake LocationManager available for testing that maintains a steady pace
 -- allow changing the pace via temporary test buttons (faster, slower -- no directly modifying distance)
 -- the fake can use a timer to send distance updates regularly, calculated from the last distance + (current pace * time since last distance)
 -- have a constant that determines whether or not the test buttons are visible and whether or not the fake location manager is used
 -- might want to call this the TeamRunModel and the location manager would just be part of it, and I could get rid of the silly singleton interface
 
 - read up on good iOS design
 -- maybe I should have an explicit model (see above reference to TeamRunModel)? 
 
 - design a good UI
 -- experiment with colors and images
 -- create a single object that represents a Run
 -- there are too many things floating around this view controller and it is getting hard to keep them straight
 -- how to have multiple storyboard elements where there is a main screen that leads to others and back to the main screen
 -- -- (maybe write a test app following a tutorial)
 -- automatic testing
 -- how users can report bugs (providing logs, stack trace, and/or a dump?), and how I can quickly diagnose/fix them 
 -- learn how to use an image manipulation tool, or maybe find a collection of good stock images
 -- find a friend who is good at (iOS preferably) UI design and ask for advice
 
 - design an automated application level test (e.g. to confirm that settings are saved properly)
 
 - try having one voice for positive notifications and another voice for negative notifications
 
 - synchronize distance/times between players
 -- if I just send distances and there is a couple second delay, then two runners running side by side will both report being ahead of each other
 
 Misc Notes
 
     Current Pace Fluctuations:
     
     -  current pace fluctautes too wildly: this problem must be well studied: read up on the best solution to gps discrete location updates to
        calculate current speed
     -- Kalman Filters
     ---- try https://github.com/lacker/ikalman/blob/master/gps.h
     -- I'm currently probably just going to settle with Apple's CLLocation speed
     ---- Apple's speed calculation probably uses Kalman filters and might leverage additional info in the GPS anyway to deliver superior results,
     e.g. maybe it uses "frequency shift (Doppler shift) of the GPS D-band carrier" http://gpsinformation.net/main/gpsspeed.htm
     
     experiments with PSLocationManager kNumSpeedHistoriesToAverage:
     
     s: last 3 - bad: fluctuate crazily
     j: last 4 - seems about just as bad: fluctuate crazily (see below)
     
     I get a distance update about once every 2 seconds
     
     so 4*2 = 8 seconds -- this currently seems to fluctuate crazily, like from 7 minute pace to 10 minute pace to 11:30 minute pace,
     so 8 seconds isn't enough
     
     what if I doubled this to 16 seconds -- that sounds more reasonable I think
     
     j: last 8 -- I just tried this out and when I was running a steady pace, this seemed reasonable: nice steady current pace
     -- this seems to deal well with the noise (before with last 4, when I was running at a steady pace it seemed to fluctuate pretty wildly,
        which I guess was due to noise)
     -- this didn't seem to be *current* enough -- when I started sprinting, there was a delay in it being represented, and then when I basically 
        stopped running, there was a long delay in the pace going back up... I think the pace might have actually continued to get faster *after*
        I stopped (I'm not certain about this)
     -- this isn't good enough, I guess I could just try 6, but this simple algorithm doesn't seem good enough
     
     
     j: last 6 -- felt just as steady as last 8 when trying to run at a steady pace (seemed better than last 4),
     but when sprinting delay again seemed very long, and stopping still showed a running speed for a while
 
 UI Design: I experimented with a Tab Bar Controller, and using Toolbars, but I don't think either fit with my buttons and views
 (e.g. tabs don't work because leaderboards is not a tab, and toolbar isn't supposed to be used to change views).
 I also tried implementing the settings screen as a table view, but the scrolling seemed unnecessary and it didn't
 look good either.  I also tried setting the background to an empty table view, but that also looked poor.
 The settings and main screen are good enough as is, stop fiddling!
 
 */

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
<GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate, PSLocationManagerDelegate, UIActionSheetDelegate, TeamRunLogger>

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

static const double MILES_PER_METER = 0.000621371;

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
    
    [self authenticateLocalPlayer];
    [self logDebug:@"Authenticating player..."];
    
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
            
            message = [[NSString alloc] initWithFormat:@"%@\n\nThere are %d minutes remaining in your run with %@.", message, remainingMinutes, playerNames];
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
        [self logTrace:@"Updated lastRecordedMilesOtherPlayerRan: %@ (scaling factor %@)", truncateToTwoDecimals(lastRecordedMilesOtherPlayerRan), truncateToTwoDecimals(scalingFactor)];
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
    
    [self logTrace:@"targetMilesRanIfRunningAtTargetMilePace = %@, seconds: %d, target seconds per mile: %d", truncateToTwoDecimals(targetMilesRanIfRunningAtTargetMilePace), (int) [PSLocationManager sharedLocationManager].totalSeconds, [TeamRunSettings targetSecondsPerMile]];
    
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

#pragma mark - Logging
////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   Logging Related Methods
//
////////////////////////////////////////////////////////////////////////////////////////////////////

// todo: consider using CocoaLumberjack logging framework

- (void)logTrace:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_TRACE message:message];
}

- (void)logDebug:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_DEBUG message:message];
}

- (void)logInfo:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_INFO message:message];
}

- (void)logWarn:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_WARN message:message];
}

- (void)logError:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_ERROR message:message];
}

- (void)logTmp:(NSString*)format,...
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    [self logWithLevel:LOG_TEMP_ESCALATION message:message];
}

- (void)logWithLevel:(LogLevel)level message:(NSString*)message
{
    static LogLevel currentLevel = LOG_DEBUG;
    
    if (level >= currentLevel)
    {
        NSLog(@"%@", message);
        [self.scrollingText setText:[NSString stringWithFormat:@"%@\n\n%@", [self.scrollingText text], message]];
        
        [self.scrollingText scrollRangeToVisible:NSMakeRange([self.scrollingText.text length], 0)];
    }
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
            [self logError:@"Todo: better handle user authentication failure -- error: %@", error];
        }
    };
}

- (void)playerAuthenticated
{
    [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {
        // Insert game-specific code here to clean up any game in progress.
        
        [self logDebug:@"invite handler called with acceptedInvite nil? %@, playersToInvite count: %d", acceptedInvite == nil, playersToInvite.count];
        
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
    [self logTrace:@"Match cancelled"];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self logError:@"matchmaker failed with error: %@", error];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    match.delegate = self;
    self.match = match;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self logTrace:@"Match found -- expectedPlayerCount: %d", match.expectedPlayerCount];
    
    if (runInProgress) [self logError:@"runInProgress should be false if didFindMatch called"];
    
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
            withMessage = [[NSString alloc] initWithFormat:@" with %@", playerNames];
        }
        
        NSString* facebookMessage = [[NSString alloc] initWithFormat:@"I completed a %@ mile run%@", truncateToTwoDecimals(rawMiles), withMessage];

        [self presentViewController:completionViewController animated:YES completion:nil];
        
        [completionViewController setMilesRan:rawMiles
                                      seconds:[PSLocationManager sharedLocationManager].totalSeconds
                                    teamMiles:teamRunMiles
                                       logger:self
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
    [self logTrace:@"takes ~10 seconds for GPS shutdown"];
}

- (void)updatePlayers
{
    if (self.match != nil)
    {
        [GKPlayer loadPlayersForIdentifiers:self.match.playerIDs withCompletionHandler:^(NSArray *players, NSError *error)
        {
            [self logTrace:@"loadPlayersForIdentifiers completion handler called"];
            if (error != nil)
            {
                [self logError:@"Error loading player information: %@", error];
                
                // todo: consider retrying to get players
            }
            
            self.players = players;
            [self logTrace:@"players set: %@", self.players];
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
            [self logDebug:@"player (%@) connected (%d\nexpected player count is now %d)", playerID, match.expectedPlayerCount];
            break;
        case GKPlayerStateDisconnected:
            [self logWarn:@"player (%@) disconnected (%d\nexpected player count is now %d)", playerID, match.expectedPlayerCount];
            break;
        default:
            [self logError:@"match (%@) player (%@) unrecognized state (%d), expected player count is now %d", match.description, playerID, state, match.expectedPlayerCount];
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
        
        [self logTrace:@"player %@: %f miles (%d seconds target mile pace)", playerID, message->milesRan, message->secondsPerMileTargetPace];
        
        [self updateMilesAhead:message->milesRan targetSecondsPerMile:message->secondsPerMileTargetPace];
    }
    else
    {
        [self logWarn:@"discarding unsupported message of length %d from player %@", [data length], playerID];
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
    
    [self logTrace:@"Signal strength changed to %@", strengthText];
}

- (void)locationManagerSignalConsistentlyWeak:(PSLocationManager *)locationManager {
    [self logTrace:@"Signal strength consistently weak"];
}

- (void)locationManager:(PSLocationManager *)locationManager distanceUpdated:(CLLocationDistance)distance /* distance in meters */
{    
    const float milesRan = distance*MILES_PER_METER;
    [self.milesRanLabel setText:truncateToTwoDecimals(milesRan)];
    [self logTrace:@"%f miles", milesRan];
    
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
            [self logError:@"error sending data to players: %@", error.description];
        }
    }
    
    [self updateMilesAhead];
}

- (void)locationManager:(PSLocationManager *)locationManager waypoint:(CLLocation *)waypoint calculatedSpeed:(double)calculatedSpeed
{
    if (runInProgress)
    {
        [self logTrace:@"Location Update %@:\n\tPS: %@\n\tCL: %@\n\tDelta:%f\n",
         truncateToTwoDecimals([PSLocationManager sharedLocationManager].totalSeconds),
         truncateToTwoDecimals(calculatedSpeed),
         truncateToTwoDecimals(waypoint.speed),
         calculatedSpeed - waypoint.speed
         ];
        
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
    [self logError:@"LocationManager error: %s", error];
}

#pragma mark - OpenEars
////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   OpenEars Methods
//
////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) say:(NSString*)textToSay
{
    [self logTrace:@"say %@", textToSay];
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

NSString* minutesPerMilePaceString(const double metersPerSecond, bool verbose)
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
    
    NSString* noPace = verbose ? @"0 minutes and 0 seconds" : @"0:00";
    
    if (milesPerSecond > 0) // prevent divide by zero errors
    {
        const int secondsPerMile = round(1.0 / milesPerSecond);
        
        const int paceMinutes = secondsPerMile / 60;
        const int paceSeconds = secondsPerMile % 60;
        
        if (paceMinutes > 59)
        {
            return noPace;
        }
        else
        {
            return verbose ? [NSString stringWithFormat:@"%d minutes and %d seconds", paceMinutes, paceSeconds]
                           : [NSString stringWithFormat:@"%d:%02d", paceMinutes, paceSeconds];
        }
    }
    return noPace;
}

@end
