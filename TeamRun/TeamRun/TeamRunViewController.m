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
<GKMatchmakerViewControllerDelegate, GKMatchDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
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

- (void)configureAudio;

- (void)createMatch;
- (void)startRunWithMatch:(GKMatch*)match players:(NSArray*)players;
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
    
    setScrollingLogText(self.scrollingText);
    
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
    
    [self configureAudio];
}

- (void)configureAudio
{
    NSError *error = nil;
    
    if (! [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                           withOptions:AVAudioSessionCategoryOptionDuckOthers
                                                 error:&error])
    {
        LOG_ERROR(@"Unable to set audio category: %@", error);
    }
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    LOG_DEBUG(@"button index %d", buttonIndex);
    switch (buttonIndex) {
        // the start run prompt has 2 buttons (1. Multiplayer, 2. Single Player)
        // all other prompts only have a single dismiss/OK button (with buttonIndex 0)
        case 1:
            [self createMatch];
            break;
        case 2:
            [self startRunWithMatch:nil players:nil];
            break;
        default:
            break;
    }
}

- (IBAction)startStopButtonClicked:(id)sender
{
    if (self.run == nil)
    {
        UIAlertView* runPrompt = [[UIAlertView alloc] initWithTitle:@"Run with a friend or solo?" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Multiplayer", @"Single Player", nil];
        [runPrompt show];
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

    if (self.run.secondsRemaining <= 0)
    {
        LOG_INFO(@"run is over, so ending team run");
        [self endRun];
    }
}

- (void)speakNotification:(NSTimer *)timer
{
    const int secondsRan = self.run.seconds;
    NSString* durationRan = secondsRan >= 60 ? [NSString stringWithFormat:@"%d minutes %d seconds", secondsRan/60, secondsRan % 60]
                                             : [NSString stringWithFormat:@"%d seconds", secondsRan];
        
    NSString* pace = minutesPerMilePaceString(self.run.averageMetersPerSecond, true);
    
    NSString* paceNotification = [NSString stringWithFormat:@"You have run %@, %@ miles, at %@ mile pace.", durationRan, truncateToTwoDecimals(self.run.miles), pace];
    
    // todo: some of this relative position logic is duplicated in refreshRunDisplay -- consider refactoring to remove the duplication
    
    const double milesAhead = self.run.milesAhead;
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
    // update pace views
    [self.currentPaceLabel setText:minutesPerMilePaceString(self.run.currentMetersPerSecond, false)];
    [self.averagePaceLabel setText:minutesPerMilePaceString(self.run.averageMetersPerSecond, false)];
    
    // next update distance and miles ahead views
    {
        [self.milesRanLabel setText:truncateToTwoDecimals(self.run.miles)];
        LOG_DEBUG(@"targetMilesRanIfRunningAtTargetMilePace = %@, seconds: %d, target seconds per mile: %d", truncateToTwoDecimals(self.run.targetMiles), (int) self.run.seconds, [TeamRunSettings targetSecondsPerMile]);
        
        const double milesAhead = self.run.milesAhead;
        
        if ( absoluteValue(milesAhead) < ON_PACE_THRESHOLD_MILES)
        {
            [self.milesAheadLabel setText:@"on pace"];
        }
        else
        {
            NSString* aheadOrBehind = (milesAhead >= 0) ? @"ahead" : @"behind";
            [self.milesAheadLabel setText:[NSString stringWithFormat:@"%@ mi %@", truncateToTwoDecimals(absoluteValue(milesAhead)), aheadOrBehind]];
        }
    }
    
    // finally update time ran view
    if (self.run.isSinglePlayer)
    {
        const double secondsRan = self.run.seconds;
        [self.timeLabel setText:[NSString stringWithFormat:@"%d:%02d", (int) (secondsRan / 60), ((int) secondsRan) % 60]];
    }
    else
    {
        const int secondsRemaining = round(self.run.secondsRemaining);
        
        [self.timeLabel setText:[NSString stringWithFormat:@"%d:%02d", secondsRemaining / 60, secondsRemaining % 60]];
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

- (void)createMatch
{
    if ([GKLocalPlayer localPlayer].playerID != nil) // todo: is this the right way to check if logged in?
    {
        // todo: remove duplicate code from here and invite handler
        GKMatchRequest *request = [[GKMatchRequest alloc] init];
        request.minPlayers = 2;
        request.maxPlayers = 2;
        request.defaultNumberOfPlayers = 2;
        
        GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
        mmvc.matchmakerDelegate = self;
        
        [self presentViewController:mmvc animated:YES completion:nil];
    }
    else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Game Center Login Required" message:@"Login with the Game Center app" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    LOG_DEBUG(@"Match cancelled");
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    LOG_ERROR(@"match failed with error: %@", error);
    [self dismissViewControllerAnimated:YES completion:nil];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Multiplayer failed" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    LOG_DEBUG(@"Did find match: %@", match);
    // we need to de-activate the audio session to unduck any background music that might be playing -- the audio session was started by game center to play the stupid trumpet sound that I don't know how to disable
    NSError *activationError = nil;
    if (![[AVAudioSession sharedInstance] setActive:FALSE error: &activationError])
    {
        LOG_ERROR(@"Unable to de-activate the audio session: %@", activationError);
    }
    
    [GKPlayer loadPlayersForIdentifiers:match.playerIDs withCompletionHandler:^(NSArray *players, NSError *error)
    {
        LOG_DEBUG(@"loadPlayersForIdentifiers completion handler called");
        if (error != nil)
        {
            LOG_ERROR(@"Error loading player information: %@", error);
            // todo: display a message that players counldn't be found and to try auto-match on Sunday at 11 AM EST.
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Match Making Failed" message:@"If you have trouble finding a running buddy, try Sunday at 11 AM EST" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            LOG_WARN(@"Disconnecting from match with no players");
            [match disconnect];
        }
        else
        {
            LOG_DEBUG(@"starting match with players: %@", players);

            match.delegate = self;

            LOG_DEBUG(@"Match found -- expectedPlayerCount: %d", match.expectedPlayerCount);

            if (self.run != nil) LOG_ERROR(@"self.run should be nil if didFindMatch called");

            if (self.run == nil && match.expectedPlayerCount == 0)
            {
                [self startRunWithMatch:match players:players];
            }
        }
     }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)startRunWithMatch:(GKMatch*)match players:(NSArray*)players
{
    self.run = [[TeamRun alloc] initWithMatch:match players:players];

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
    [self.runningTimer invalidate];
    self.runningTimer = nil;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    TeamRunCompletedViewController *completionViewController = [storyboard instantiateViewControllerWithIdentifier:@"RunCompletedViewController"];
    
    {
        // todo: we should probably just be passing the run object here
        
        const double rawMiles = self.run.miles;
        const double teamRunMiles = self.run.isSinglePlayer ? rawMiles
                                                            : rawMiles + self.run.milesOtherPlayerRan;
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
    
    [self updateNotificationsTimerIfNecessary];
    
    [self.startStopButton setActionSheetButtonWithColor: runGreen];
    [self.startStopButton setTitle:@"Run" forState:UIControlStateNormal];
}

- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
    switch (state)
    {
        case GKPlayerStateConnected:
            LOG_DEBUG(@"player (%@) connected (expected player count is now %d)", playerID, match.expectedPlayerCount);
            break;
        case GKPlayerStateDisconnected:
            LOG_DEBUG(@"player (%@) disconnected (expected player count is now %d)", playerID, match.expectedPlayerCount);
            break;
        default:
            LOG_ERROR(@"match (%@) player (%@) unrecognized state (%d), expected player count is now %d", match.description, playerID, state, match.expectedPlayerCount);
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
    
    // only add text to the speach queue if no speach is currently in progress -- this prevents accumulating old audio notifications
    if (fliteController.speechInProgress == false)
    {        
        // creating the audio from text takes a second or two to create (before it starts playing),
        // and this noticibly ties up the main thread preventing user interaction (e.g. buttons don't respond to taps),
        // so we execute this asynchronously
        dispatch_async(speachQueue, ^{ [fliteController say:textToSay withVoice:voice]; });
    }
}

@end
