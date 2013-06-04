//
//  TeamRunCompletedViewController.m
//  teamrun
//
//  Created by John DiMatteo on 5/2/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
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

#import "TeamRunCompletedViewController.h"
#import "TeamRunUtility.h"

#import "UIGlossyButton.h"

#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <GameKit/GameKit.h>

@interface TeamRunCompletedViewController ()
<GKGameCenterControllerDelegate>

- (IBAction)openLeaderboards:(id)sender;
- (IBAction)doneTapped;
- (IBAction)facebookTapped;
@property (weak, nonatomic) IBOutlet UIGlossyButton *facebookButton;

@property (weak, nonatomic) IBOutlet UILabel *currentRunRawMilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentRunTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentRunPaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentRunTeamMilesLabel;

@property (weak, nonatomic) IBOutlet UILabel *bestRunRawMilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *bestRunTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *bestRunPaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *bestRunTeamMilesLabel;

@property (weak, nonatomic) IBOutlet UILabel *totalRawMilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTeamMilesLabel;

@property (weak, nonatomic) IBOutlet UILabel *teamMilesRowLabel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

- (void) reportScore: (int64_t) score
    forLeaderboardID: (NSString*) category
               addTo: (NSMutableDictionary*) categoryToCurrentScore;

@property (nonatomic) int remainingScoresToLoad;

@property (strong, nonatomic) NSString* initialPostMessage;

@end

@implementation TeamRunCompletedViewController

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
	// Do any additional setup after loading the view.
    
    UIColor* facebookBlue = [UIColor colorWithRed:0.164215 green:0.234407 blue:0.571473 alpha:1];
    [self.facebookButton setActionSheetButtonWithColor:[UIColor whiteColor]];
    [self.facebookButton setTitleColor:facebookBlue forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)facebookTapped
{
    SLComposeViewController *postSheet = [[SLComposeViewController alloc] init];
    postSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [postSheet setInitialText:self.initialPostMessage];
    [postSheet addURL:[NSURL URLWithString:@"http://teamrun.org/"]];
    [self presentViewController:postSheet animated:YES completion:nil];
    
    [postSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
        switch (result) {
            case SLComposeViewControllerResultCancelled:
                LOG_INFO(@"Post cancelled");
                break;
            case SLComposeViewControllerResultDone:
                LOG_INFO(@"Post successfull");
                break;
            default:
                LOG_ERROR(@"Unexpected post result: %@", result);
                break;
        }
    }];
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

- (IBAction)doneTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setMilesRan:(double)rawMiles
            seconds:(int)seconds
          teamMiles:(double)teamMiles
    facebookMessage:(NSString*)message
{
    // todo: this function is a mess, clean it up!

    self.initialPostMessage = message;
    
    [self.currentRunRawMilesLabel setText:truncateToTwoDecimals(rawMiles)];
    [self.currentRunTimeLabel setText:[NSString stringWithFormat:@"%.2d:%.2d", seconds / 60, seconds % 60]];
    [self.currentRunTeamMilesLabel setText:truncateToTwoDecimals(teamMiles)];
    
    {
        const int secondsPerMile = rawMiles > 0 ? seconds/rawMiles : 0;
        [self.currentRunPaceLabel setText:[NSString stringWithFormat:@"%.2d:%.2d", secondsPerMile / 60, secondsPerMile % 60]];
    }
    
    NSMutableDictionary* categoryToCurrentScore = [NSMutableDictionary dictionaryWithCapacity:3];
    [self reportScore:rawMiles*100 forLeaderboardID:@"grp.org.teamrun.SingleRunRawMiles" addTo:categoryToCurrentScore];
    [self reportScore:teamMiles*100 forLeaderboardID:@"grp.org.teamrun.SingleRunTeamMiles" addTo:categoryToCurrentScore];
    [self reportScore:seconds forLeaderboardID:@"grp.org.teamrun.SingleRunSeconds" addTo:categoryToCurrentScore];
    [self reportScore:seconds/rawMiles forLeaderboardID:@"grp.org.teamrun.SingleRunSecondsPerMile" addTo:categoryToCurrentScore];
        
    if ([GKLocalPlayer localPlayer].playerID == nil)
    {
        [self.totalRawMilesLabel setText:@"Personal bests and total miles require Game Center login"];
        [self.loadingIndicator stopAnimating];
    }
    else
    {
        NSArray* currentPlayer = @[[GKLocalPlayer localPlayer].playerID];
        
        NSArray* totalScoreCateogries = @[@"grp.org.teamrun.TotalRawMiles", @"grp.org.teamrun.TotalTeamMiles"];
        
        self.remainingScoresToLoad = categoryToCurrentScore.count + totalScoreCateogries.count;
        
        // note: I am not using any GKScore formattedValue properties because these are null for scores that I initialize (they are only set for downloaded scores)
        
        for (NSString* scoreCategory in categoryToCurrentScore.allKeys)
        {
            GKLeaderboard *bestScoreRequest = [[GKLeaderboard alloc] initWithPlayerIDs:currentPlayer];
            if (bestScoreRequest != nil)
            {
                bestScoreRequest.timeScope = GKLeaderboardTimeScopeAllTime;
                bestScoreRequest.category = scoreCategory;
                bestScoreRequest.range = NSMakeRange(1,1);
                [bestScoreRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
                    if (error != nil)
                    {
                        LOG_ERROR(@"%@ loadScoresWithCompletionHandler error: %@", scoreCategory, error);
                    }
                    if (scores != nil)
                    {
                        if (scores.count > 0)
                        {
                            GKScore* personalBest = scores[0];
                            GKScore* currentScore = categoryToCurrentScore[scoreCategory];
                            
                            if (currentScore.value > personalBest.value)
                            {
                                personalBest = currentScore;
                            }
                            
                            NSString* formattedMiles = truncateToTwoDecimals(personalBest.value/100.0);
                            
                            if ([scoreCategory isEqualToString:@"grp.org.teamrun.SingleRunRawMiles"])
                            {
                                [self.bestRunRawMilesLabel setText:formattedMiles];
                            }
                            else if ([scoreCategory isEqualToString:@"grp.org.teamrun.SingleRunTeamMiles"])
                            {
                                [self.bestRunTeamMilesLabel setText:formattedMiles];
                            }
                            else if ([scoreCategory isEqualToString:@"grp.org.teamrun.SingleRunSeconds"])
                            {
                                const int bestSeconds = personalBest.value;
                                [self.bestRunTimeLabel setText:[NSString stringWithFormat:@"%.2d:%.2d", bestSeconds/ 60, bestSeconds % 60]];
                            }
                            else if ([scoreCategory isEqualToString:@"grp.org.teamrun.SingleRunSecondsPerMile"])
                            {
                                const int bestSecondsPerMile = personalBest.value;
                                [self.bestRunPaceLabel setText:[NSString stringWithFormat:@"%.2d:%.2d", bestSecondsPerMile / 60, bestSecondsPerMile % 60]];
                            }
                            else
                            {
                                LOG_ERROR(@"Unexpected category in loop: %@", scoreCategory);
                            }

                        }
                    }
                    self.remainingScoresToLoad--;
                    if (self.remainingScoresToLoad == 0)
                    {
                        [self.loadingIndicator stopAnimating];
                    }
                }];
            }
            else
            {
                LOG_ERROR(@"%@ bestScoreRequest is nil", scoreCategory);
                
                self.remainingScoresToLoad--;
                if (self.remainingScoresToLoad == 0)
                {
                    [self.loadingIndicator stopAnimating];
                }
            }
        }
        
        for (NSString* scoreCategory in totalScoreCateogries)
        {
            GKLeaderboard *totalScoreRequest = [[GKLeaderboard alloc] initWithPlayerIDs:currentPlayer];
            if (totalScoreRequest != nil)
            {
                totalScoreRequest.timeScope = GKLeaderboardTimeScopeAllTime;
                totalScoreRequest.category = scoreCategory;
                totalScoreRequest.range = NSMakeRange(1,1);
                [totalScoreRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
                    if (error != nil)
                    {
                        LOG_ERROR(@"%@ loadScoresWithCompletionHandler error: %@", scoreCategory, error);
                    }
                    GKScore* currentScore = [scoreCategory isEqualToString:@"grp.org.teamrun.TotalRawMiles"]
                                          ? categoryToCurrentScore[@"grp.org.teamrun.SingleRunRawMiles"]
                                          : categoryToCurrentScore[@"grp.org.teamrun.SingleRunTeamMiles"];
                    
                    GKScore* totalScore = [[GKScore alloc] initWithCategory:scoreCategory];
                    totalScore.value = currentScore.value; // temporarily set to just the current score
                    totalScore.context = 0;
                    
                    if (scores != nil && scores.count > 0)
                    {
                        totalScore.value += ((GKScore*)scores[0]).value;
                    }
                    
                    [totalScore reportScoreWithCompletionHandler:^(NSError *error) {
                        if (error != nil) LOG_ERROR(@"%@ reportScoreWithCompletionHandler error: %@", scoreCategory, error);
                        // game center will automatically resend the score later
                    }];
                    
                    NSString* formattedScore = truncateToTwoDecimals(totalScore.value/100.0);
                    
                    if ([scoreCategory isEqualToString:@"grp.org.teamrun.TotalRawMiles"])
                    {
                        [self.totalRawMilesLabel setText:[NSString stringWithFormat:@"%@ total miles", formattedScore]];
                    }
                    else
                    {
                        [self.totalTeamMilesLabel setText:[NSString stringWithFormat:@"%@ total team miles", formattedScore]];
                    }
                    
                    self.remainingScoresToLoad--;
                    if (self.remainingScoresToLoad == 0)
                    {
                        [self.loadingIndicator stopAnimating];
                    }
                }];
            }
            else
            {
                LOG_ERROR(@"%@ totalScoreRequest is nil", scoreCategory);
                
                self.remainingScoresToLoad--;
                if (self.remainingScoresToLoad == 0)
                {
                    [self.loadingIndicator stopAnimating];
                }
            }
        }
    }
}

- (void) reportScore: (int64_t) score
    forLeaderboardID: (NSString*) category
               addTo: (NSMutableDictionary*) categoryToCurrentScore
{
    GKScore *scoreReporter = [[GKScore alloc] initWithCategory:category];
    scoreReporter.value = score;
    scoreReporter.context = 0;
    
    [scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
        if (error != nil) LOG_ERROR(@"%@ reportScoreWithCompletionHandler error: %@", category, error);
        // game center will automatically resend the score later
        // todo: test that this really is automatically resent
    }];
    
    categoryToCurrentScore[category]=scoreReporter;
}
@end
