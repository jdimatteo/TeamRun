//
//  TeamRunViewController.m
//  TeamRun
//
//  Created by John DiMatteo on 12/10/12.
//  Copyright (c) 2012 John DiMatteo. All rights reserved.
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

#import "TeamRunViewController.h"
#import "TeamRunUtility.h"
#import "TeamRunCompletedViewController.h"
#import "TeamRunSettings.h"
#import "TeamRunLogger.h"
#import "TeamRun.h"

#import "UIGlossyButton.h"

#import <Awb/Awb.h>
#import <OpenEars/FliteController.h>
#import <OpenEars/AudioSessionManager.h>

#import <GameKit/GameKit.h>

#import <AudioToolbox/AudioSession.h>

@interface TeamRunViewController ()
<GKMatchmakerViewControllerDelegate, GKMatchDelegate, UIActionSheetDelegate>
{
    FliteController *fliteController;
    Awb *voice;
    
    dispatch_queue_t speachQueue;
    
    UIColor* runGreen;
    UIColor* stopRed;
}

- (IBAction)startStopButtonClicked:(id)sender;

@property (weak, nonatomic) IBOutlet UITextView *scrollingText;
@property (weak, nonatomic) IBOutlet UIGlossyButton *startStopButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *averagePaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *milesRanLabel;
@property (weak, nonatomic) IBOutlet UILabel *milesAheadLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeDescriptionLabel;

- (void)createMatch;
- (void)startRunWithMatch:(GKMatch*)match;
- (void)endRun;
- (void)playerAuthenticated;

- (void)secondRan:(NSTimer *)timer;
- (void)speakNotification:(NSTimer *)timer;
- (void)updateNotificationsTimerIfNecessary;
- (void)refreshRunDisplay;
- (void)refreshRunDisplay:(NSNotification *)notif;

@property (strong, nonatomic) TeamRun* run; // current run, nil if no run in progress

@property (nonatomic) NSTimer* runningTimer;
@property (nonatomic) NSTimer* paceUpdateTimer;

@end

// gps could be off by 20 meters, so if there are two of them a difference of less than 40 meters
// could just be noise.  40 meters is about .0249 miles, so don't report any difference less than .025 miles
static const double ON_PACE_THRESHOLD_MILES = 0.025;

@implementation TeamRunViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [TeamRunLogger setScrollingLogText:self.scrollingText];
    
    [TeamRun startWarmingUpGPS];
    
    [self authenticateLocalPlayer];
    LOG_INFO(@"Authenticating player...");
    
    // following causes open ears speach to work while running in the background or locked
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [[AudioSessionManager sharedAudioSessionManager]setSoundMixing:YES];
    
    speachQueue = dispatch_queue_create("org.TeamRun.SpeachQueue", NULL);
    
    self.scrollingText.hidden = true; // hide unless needed for debugging
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshRunDisplay:)
                                                 name:NOTIF_RunStateChanged object:nil];
    
    runGreen = [UIColor colorWithRed:6/256.0 green:122/256.0 blue:24/256.0 alpha:1];
    stopRed = [UIColor redColor];
    
	[self.startStopButton setActionSheetButtonWithColor: runGreen];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateNotificationsTimerIfNecessary];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    if (self.run == nil)
    {
        if ([TeamRunSettings multiplayerMode])
        {
            [self createMatch];
        }
        else
        {
            [self startRunWithMatch:nil];
        }
    }
    else
    {
        NSString *message = @"Are you sure you want to end your run?";
        
        NSString *playerNames = self.run.playerNames;
        
        if (playerNames.length > 0)
        {
            const int remainingMinutes = (30*60 - round(self.run.seconds))/60;
            
            message = [NSString stringWithFormat:@"%@\n\nThere are %d minutes remaining in your run with %@.", message, remainingMinutes, playerNames];
        }
        
        UIActionSheet *endRunConfirmationPrompt = [[UIActionSheet alloc] initWithTitle:message delegate:self cancelButtonTitle:@"Keep Running" destructiveButtonTitle:@"End Run" otherButtonTitles:nil];
        
        endRunConfirmationPrompt.actionSheetStyle = UIBarStyleBlackOpaque;
        [endRunConfirmationPrompt showInView:self.view];
    }
}

- (void)secondRan:(NSTimer *)timer
{
    [self refreshRunDisplay];
}

- (void)speakNotification:(NSTimer *)timer
{
    const int secondsRan = self.run.seconds;
    NSString* durationRan = secondsRan >= 60 ? [NSString stringWithFormat:@"%d minutes %d seconds", secondsRan/60, secondsRan % 60]
                                             : [NSString stringWithFormat:@"%d seconds", secondsRan];
        
    NSString* pace = minutesPerMilePaceString(self.run.averageMetersPerSecond, true);
    
    NSString* paceNotification = [NSString stringWithFormat:@"You have run %@, %@ miles, at %@ mile pace.", durationRan, truncateToTwoDecimals(self.run.miles), pace];
    
    const double milesAhead = self.run.milesOtherPlayerRan;
    
    NSString* relativePositionNotification = absoluteValue(milesAhead) > ON_PACE_THRESHOLD_MILES
        ? [NSString stringWithFormat:@"You are about %@ miles %@.", truncateToTwoDecimals(absoluteValue(milesAhead)), milesAhead >= 0 ? @"ahead" : @"behind"]
        : @"You are on pace";
    
    NSString* notification = [NSString stringWithFormat:@"%@ %@",
                              [TeamRunSettings paceNotificationsEnabled] ? paceNotification : @"",
                              [TeamRunSettings relativePositionNotificationsEnabled] ? relativePositionNotification : @""];
    [self say:notification];
}

- (void)updateNotificationsTimerIfNecessary
{
    bool notifications = [TeamRunSettings notificationsEnabled] && self.run != nil;
    
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

- (void)refreshRunDisplay:(NSNotification *)notif
{
    [self refreshRunDisplay];
}

- (void)refreshRunDisplay
{
    // first save the values used in multiple calculations at about the same time so they are consistent
    const double milesRan = self.run.miles;
    const double targetMilesRanIfRunningAtTargetMilePace = self.run.targetMiles;
    const double secondsRan = self.run.seconds;
    
    // now update pace views
    [self.currentPaceLabel setText:minutesPerMilePaceString(self.run.currentMetersPerSecond, false)];
    [self.averagePaceLabel setText:minutesPerMilePaceString(self.run.averageMetersPerSecond, false)];
    
    // next update distance and miles ahead views
    {
        [self.milesRanLabel setText:truncateToTwoDecimals(milesRan)];
        LOG_DEBUG(@"targetMilesRanIfRunningAtTargetMilePace = %@, seconds: %d, target seconds per mile: %d", truncateToTwoDecimals(targetMilesRanIfRunningAtTargetMilePace), (int) self.run.seconds, [TeamRunSettings targetSecondsPerMile]);
        
        const double referenceMiles = self.run.isMultiplayer ? self.run.milesOtherPlayerRan : targetMilesRanIfRunningAtTargetMilePace;
        const double milesAhead = milesRan - referenceMiles;
        
        if ( absoluteValue(milesAhead) < ON_PACE_THRESHOLD_MILES)
        {
            [self.milesAheadLabel setText:@"on pace"];
        }
        else
        {
            NSString* aheadOrBehind = (milesRan >= referenceMiles) ? @"ahead" : @"behind";
            [self.milesAheadLabel setText:[NSString stringWithFormat:@"%@ mi %@", truncateToTwoDecimals(absoluteValue(milesAhead)), aheadOrBehind]];
        }
    }
    
    // finally update time ran view
    if (self.run.isSinglePlayer)
    {
        [self.timeLabel setText:[NSString stringWithFormat:@"%d:%02d", (int) (secondsRan / 60), ((int) secondsRan) % 60]];
    }
    else
    {
        // all multiplayer runs are 30 minutes long
        const int remainingSeconds = 30*60 - round(secondsRan);
        
        if (remainingSeconds <= 0)
        {
            [self endRun];
        }
        else
        {
            [self.timeLabel setText:[NSString stringWithFormat:@"%d:%02d", remainingSeconds / 60, remainingSeconds % 60]];
        }
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
    
    [self dismissViewControllerAnimated:YES completion:nil];
    LOG_DEBUG(@"Match found -- expectedPlayerCount: %d", match.expectedPlayerCount);
    
    if (self.run != nil) LOG_ERROR(@"self.run should be nil if didFindMatch called");
    
    if (self.run == nil && match.expectedPlayerCount == 0)
    {
        [self startRunWithMatch:match];
    }
}

- (void)startRunWithMatch:(GKMatch*)match
{
    self.run = [[TeamRun alloc] initWithMatch:match];

    self.runningTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(secondRan:)
                                                       userInfo:nil
                                                        repeats:YES];
    
    [self.startStopButton setActionSheetButtonWithColor: stopRed];
    [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
    
    [self updateNotificationsTimerIfNecessary];
        
    [self.timeDescriptionLabel setText:(self.run.isSinglePlayer ? @"time ran" : @"time remaining")];
    
    [self refreshRunDisplay];
}

- (void)endRun
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    TeamRunCompletedViewController *completionViewController = [storyboard instantiateViewControllerWithIdentifier:@"RunCompletedViewController"];
    
    {
        // todo: we should probably just be passing the run object here
        
        const double rawMiles = self.run.miles;
        const double teamRunMiles = self.run.isSinglePlayer ? rawMiles
                                                            : 2*(rawMiles + self.run.milesOtherPlayerRan);
        NSString* withMessage = @"";
        NSString* playerNames = self.run.playerNames;
        if (playerNames.length > 0 )
        {
            withMessage = [NSString stringWithFormat:@" with %@", playerNames];
        }
        
        NSString* facebookMessage = [NSString stringWithFormat:@"I just ran %@ miles%@", truncateToTwoDecimals(rawMiles), withMessage];

        [self presentViewController:completionViewController animated:YES completion:nil];
        
        [completionViewController setMilesRan:rawMiles
                                      seconds:self.run.seconds
                                    teamMiles:teamRunMiles
                              facebookMessage:facebookMessage];
    }
    
    [self.run end];
    self.run = nil;
        
    [self.runningTimer invalidate];
    self.runningTimer = nil;
    
    [self updateNotificationsTimerIfNecessary];
    
    [self.startStopButton setActionSheetButtonWithColor: runGreen];
    [self.startStopButton setTitle:@"Run" forState:UIControlStateNormal];
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
    
    if (self.run == nil && match.expectedPlayerCount == 0)
    {
        [self startRunWithMatch:match];
    }
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    [self.run processData:data fromPlayer:playerID];
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

@end
