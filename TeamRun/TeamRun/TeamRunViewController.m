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

- (IBAction)OpenGameCenter;
- (IBAction)CreateMatch;

- (void)PlayerAuthenticated;

@end

@implementation TeamRunViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self authenticateLocalPlayer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Auto match works on simulator!  (Sending/receiving match invites doesn't work on simulator according to Apple docs)

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
            [self PlayerAuthenticated];
        }
        else
        {
            NSLog(@"Todo: better handle user authentication failure -- error: %@", error);
        }
    };
}

- (void)PlayerAuthenticated
{
    [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {
        
        // Insert game-specific code here to clean up any game in progress.
        
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

- (IBAction)OpenGameCenter {
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        [self presentViewController: gameCenterController animated: YES completion:nil];
    }
}

- (IBAction)CreateMatch {
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 4;
    request.defaultNumberOfPlayers = 2;
    
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
    
    [self presentViewController:mmvc animated:YES completion:nil];
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"matchmaker failed with error: %@", error);
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Match found: %@", match);
}
@end
