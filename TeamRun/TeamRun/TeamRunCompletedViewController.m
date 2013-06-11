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

- (void) process:(NSString*) identifier
                :(double) milesOrSeconds
                :(bool) formatAsSeconds
                :(UILabel*) currentLabel
                :(UILabel*) personalBestLabel
                :(UILabel*) totalLabel;

@property (weak, nonatomic) IBOutlet UIGlossyButton *facebookButton;

@property (weak, nonatomic) IBOutlet UILabel *currentRawMilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTeamMilesLabel;

@property (weak, nonatomic) IBOutlet UILabel *bestRawMilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *bestTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *bestPaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *bestTeamMilesLabel;

@property (weak, nonatomic) IBOutlet UILabel *totalRawMilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTeamMilesLabel;

@property (weak, nonatomic) IBOutlet UILabel *teamMilesRowLabel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@property (nonatomic) int remainingScoresToLoad;

@property (strong, nonatomic) NSString* initialPostMessage;

@end

@implementation TeamRunCompletedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor* facebookBlue = [UIColor colorWithRed:0.164215 green:0.234407 blue:0.571473 alpha:1];
    [self.facebookButton setActionSheetButtonWithColor:[UIColor whiteColor]];
    [self.facebookButton setTitleColor:facebookBlue forState:UIControlStateNormal];
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
        [self presentViewController:gameCenterController animated:YES completion:nil];
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
    self.initialPostMessage = message;
    
    [self.totalRawMilesLabel setText:@"total miles"];
    [self.totalTeamMilesLabel setText:@"total team miles"];
    
    self.remainingScoresToLoad = 6; // 4 personal bests + 2 totals
    
    const int secondsPerMile = rawMiles > 0 ? seconds/rawMiles : 0;
    
    //              ScoreID          score     formatAsSeconds
    [self process:@"RawMiles"       :rawMiles       :NO  :_currentRawMilesLabel  :_bestRawMilesLabel  :_totalRawMilesLabel];
    [self process:@"TeamMiles"      :teamMiles      :NO  :_currentTeamMilesLabel :_bestTeamMilesLabel :_totalTeamMilesLabel];
    [self process:@"Seconds"        :seconds        :YES :_currentTimeLabel      :_bestTimeLabel      :nil];
    [self process:@"SecondsPerMile" :secondsPerMile :YES :_currentPaceLabel      :_bestPaceLabel      :nil];
}

NSString* formattedScore(int64_t score, bool formatAsSeconds)
{
    return formatAsSeconds
         ? [NSString stringWithFormat:@"%.2lld:%.2lld", score / 60, score % 60]
         : truncateToTwoDecimals(score/100.0);
}

- (void) process:(NSString*) identifier
                :(double) milesOrSeconds
                :(bool) formatAsSeconds
                :(UILabel*) currentLabel
                :(UILabel*) personalBestLabel
                :(UILabel*) totalLabel
{
    void (^scoreProcessed)(void) = ^{
        self.remainingScoresToLoad--;
        if (self.remainingScoresToLoad == 0)
        {
            [self.loadingIndicator stopAnimating];
        }
    };
    
    const int64_t score = formatAsSeconds ? milesOrSeconds : milesOrSeconds * 100;
    [currentLabel setText:formattedScore(score, formatAsSeconds)];
    
    if ([GKLocalPlayer localPlayer].playerID != nil) // todo: is this the right way to check if logged in?
    {
        NSString* leaderboardID = [NSString stringWithFormat:@"grp.org.teamrun.SingleRun%@", identifier];
        
        GKScore *currentScore = [[GKScore alloc] initWithCategory:leaderboardID];
        currentScore.value = score;
        currentScore.context = 0;
        
        [currentScore reportScoreWithCompletionHandler:^(NSError *error) {
            if (error != nil) LOG_ERROR(@"%@ reportScoreWithCompletionHandler error: %@", leaderboardID, error);
            // game center will automatically resend the score later
            // todo: test that this really is automatically resent
        }];
        
        NSArray* currentPlayer = @[[GKLocalPlayer localPlayer].playerID];
        
        GKLeaderboard *bestScoreRequest = [[GKLeaderboard alloc] initWithPlayerIDs:currentPlayer];
        if (bestScoreRequest != nil)
        {
            bestScoreRequest.timeScope = GKLeaderboardTimeScopeAllTime;
            bestScoreRequest.category = leaderboardID;
            bestScoreRequest.range = NSMakeRange(1,1);
            [bestScoreRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
                if (error != nil)
                {
                    LOG_ERROR(@"%@ loadScoresWithCompletionHandler error: %@", leaderboardID, error);
                }
                if (scores != nil)
                {
                    if (scores.count > 0)
                    {
                        GKScore* personalBest = scores[0];
                        
                        if (currentScore.value > personalBest.value)
                        {
                            personalBest = currentScore;
                        }
                        
                        [personalBestLabel setText:formattedScore(personalBest.value, formatAsSeconds)];
                    }
                }
                scoreProcessed();
            }];
        }
        else
        {
            LOG_ERROR(@"%@ bestScoreRequest is nil", leaderboardID);

            scoreProcessed();
        }
        
        if (totalLabel != nil)
        {
            GKLeaderboard *previousTotalScore = [[GKLeaderboard alloc] initWithPlayerIDs:currentPlayer];
            if (previousTotalScore != nil)
            {
                previousTotalScore.timeScope = GKLeaderboardTimeScopeAllTime;
                previousTotalScore.category = [NSString stringWithFormat:@"grp.org.teamrun.Total%@", identifier];
                previousTotalScore.range = NSMakeRange(1,1);
                [previousTotalScore loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
                    if (error != nil)
                    {
                        LOG_ERROR(@"%@ loadScoresWithCompletionHandler error: %@", previousTotalScore.category, error);
                    }
                    
                    GKScore* newTotalScore = [[GKScore alloc] initWithCategory:previousTotalScore.category];
                    newTotalScore.value = currentScore.value; // temporarily set to just the current score
                    newTotalScore.context = 0;
                    
                    if (scores != nil && scores.count > 0)
                    {
                        newTotalScore.value += ((GKScore*)scores[0]).value;
                    }
                    
                    [newTotalScore reportScoreWithCompletionHandler:^(NSError *error) {
                        if (error != nil) LOG_ERROR(@"%@ reportScoreWithCompletionHandler error: %@", newTotalScore.category, error);
                        // game center will automatically resend the score later
                    }];
                    
                    [totalLabel setText:[NSString stringWithFormat:@"%@ %@", truncateToTwoDecimals(newTotalScore.value/100.0), totalLabel.text]];
                    
                    scoreProcessed();
                }];
            }
            else
            {
                LOG_ERROR(@"%@ previousTotalScore is nil", identifier);
                
                scoreProcessed();
            }

        }
    }
    else
    {
        [self.totalRawMilesLabel setText:@"Personal bests and total miles require Game Center login"];
        [self.totalTeamMilesLabel setText:@""];
        [self.loadingIndicator stopAnimating];
    }
}
@end
