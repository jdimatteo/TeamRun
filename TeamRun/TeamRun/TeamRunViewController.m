//
//  TeamRunViewController.m
//  TeamRun
//
//  Created by John DiMatteo on 12/10/12.
//  Copyright (c) 2012 John DiMatteo. All rights reserved.
//

// pickup here: display pace, get rid of unused UI elements,
//              send updates to other players (display to log), voice notifications (http://www.politepix.com/openears/tutorial -- use already downloaded plugin)

#import "TeamRunViewController.h"
#import "PSLocationManager.h"

#import <GameKit/GameKit.h>

@interface TeamRunViewController ()
<GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, PSLocationManagerDelegate>

- (IBAction)openGameCenter;
- (IBAction)startStopButtonClicked;

@property (weak, nonatomic) IBOutlet UITextView *scrollingText;
@property (weak, nonatomic) IBOutlet UILabel *timeRanLabel;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;

- (void)createMatch;
- (void)playerAuthenticated;
- (void)log:(NSString*)format,...;
- (void)secondRan:(NSTimer *)timer;

@property (weak, nonatomic) GKMatch* match;
@property (nonatomic) NSTimer* runningTimer;

@end

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
        
        if (acceptedInvite)
        {
            GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithInvite:acceptedInvite];
            // todo: mmvc.matchmakerDelegate = self;
            [self presentViewController:mmvc animated:YES completion:nil];
        }
        else if (playersToInvite)
        {
            GKMatchRequest *request = [[GKMatchRequest alloc] init];
            request.minPlayers = 2;
            request.maxPlayers = 4;
            request.playersToInvite = playersToInvite;
            
            GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
            // todo: mmvc.matchmakerDelegate = self;
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

////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   GPS Location Manager Related Methods
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
    
    //[self changeDistance:distance*MILES_PER_METER];
    
    const double metersPerSecond = [PSLocationManager sharedLocationManager].currentSpeed;
    [self log:@"current speed: %f m/s", metersPerSecond];
    
    //[self.currentPaceLabel setText:minutesPerMilePaceString(metersPerSecond)];
    
    //[self.averagePaceLabel setText:minutesPerMilePaceString(distance/[self.model currentRunDuration:kCFGregorianUnitsSeconds].seconds)];
}

- (void)locationManager:(PSLocationManager *)locationManager error:(NSError *)error {
    // location services is probably not enabled for the app
    [self log:@"Unable to determine location"];
}


@end
