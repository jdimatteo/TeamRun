//
//  TeamRunViewController.m
//  TeamRun
//
//  Created by John DiMatteo on 12/10/12.
//  Copyright (c) 2012 John DiMatteo. All rights reserved.
//

#import "TeamRunViewController.h"

#import <GameKit/GameKit.h>

@interface TeamRunViewController ()
<GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate>

- (IBAction)openGameCenter;
- (IBAction)startStopButtonClicked;

@property (weak, nonatomic) IBOutlet UITextView *scrollingText;


- (void)createMatch;
- (void)playerAuthenticated;
- (void)log:(NSString*)format,...;

@property (weak, nonatomic) GKMatch* match;

@end

@implementation TeamRunViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self authenticateLocalPlayer];
    [self log:@"Authenticating player..."];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

// Auto match works on simulator!  (Sending/receiving match invites doesn't work on simulator according to Apple docs)

// pickup here: add logger to populate the scrolling text, add gps, end run, change text 

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

- (IBAction)startStopButtonClicked {
    [self createMatch];
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
    
    // todo: start run logic
}


@end
