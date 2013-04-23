//
//  ActiveRunViewController.m
//  teamrun
//
//  Created by John DiMatteo on 4/22/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "ActiveRunViewController.h"

#import <GameKit/GameKit.h>

@interface ActiveRunViewController () <GKMatchmakerViewControllerDelegate>

- (void) CreateMatch;

@property (weak, nonatomic) GKMatch* match;

@end

@implementation ActiveRunViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.match == nil) [self CreateMatch];
}

- (void) CreateMatch {
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
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"matchmaker failed with error: %@", error);
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    self.match = match;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Match found: %@", match);
    
    // todo: start run logic
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
