//
//  TeamRunCompletedViewController.m
//  teamrun
//
//  Created by John DiMatteo on 5/2/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunCompletedViewController.h"
#import "TeamRunUtility.h"

#import <GameKit/GameKit.h>

@interface TeamRunCompletedViewController ()

- (IBAction)doneTapped;

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
@property (weak, nonatomic) IBOutlet UILabel *personalBestLabel;

- (void) reportScore: (int64_t) score
    forLeaderboardID: (NSString*) category
               addTo: (NSMutableDictionary*) categoryToCurrentScore;

@property (nonatomic) int remainingScoresToLoad;

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setRunMiles:(double)rawMiles inSeconds:(int)seconds withTeamRunMiles:(double)teamMiles
{
    // todo: this function is a mess, clean it up!
    
    [self.currentRunRawMilesLabel setText:truncateToTwoDecimals(rawMiles)];
    [self.currentRunTimeLabel setText:[NSString stringWithFormat:@"%.2d:%.2d", seconds / 60, seconds % 60]];
    [self.currentRunTeamMilesLabel setText:truncateToTwoDecimals(teamMiles)];
    
    NSMutableDictionary* categoryToCurrentScore = [NSMutableDictionary dictionaryWithCapacity:3];
    [self reportScore:rawMiles*100 forLeaderboardID:@"org.teamrun.SingleRunRawMiles" addTo:categoryToCurrentScore];
    [self reportScore:teamMiles*100 forLeaderboardID:@"org.teamrun.SingleRunTeamMiles" addTo:categoryToCurrentScore];
    [self reportScore:seconds forLeaderboardID:@"org.teamrun.SingleRunSeconds" addTo:categoryToCurrentScore];
    
    // todo: populate pace label and submit pace score
        
    NSArray* currentPlayer = @[[GKLocalPlayer localPlayer].playerID];
    
    NSArray* bestScoreCateogries = @[@"org.teamrun.SingleRunRawMiles", @"org.teamrun.SingleRunTeamMiles", @"org.teamrun.SingleRunSeconds"];
    
    NSArray* totalScoreCateogries = @[@"org.teamrun.TotalRawMiles", @"org.teamrun.TotalTeamMiles"];
    
    self.remainingScoresToLoad = bestScoreCateogries.count + totalScoreCateogries.count;
    
    // note: I am not using any GKScore formattedValue properties because these are null for scores that I initialize (they are only set for downloaded scores)
    
    for (NSString* scoreCategory in bestScoreCateogries)
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
                    NSLog(@"todo, remove this NSLog: %@ loadScoresWithCompletionHandler error: %@", scoreCategory, error);
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
                        
                        if ([scoreCategory isEqualToString:@"org.teamrun.SingleRunRawMiles"])
                        {
                            [self.bestRunRawMilesLabel setText:formattedMiles];
                        }
                        else if ([scoreCategory isEqualToString:@"org.teamrun.SingleRunTeamMiles"])
                        {
                            [self.bestRunTeamMilesLabel setText:formattedMiles];
                        }
                        else if ([scoreCategory isEqualToString:@"org.teamrun.SingleRunSeconds"])
                        {
                            const int bestSeconds = personalBest.value;
                            [self.bestRunTimeLabel setText:[NSString stringWithFormat:@"%.2d:%.2d", bestSeconds/ 60, bestSeconds % 60]];
                        }
                    }
                }
                self.remainingScoresToLoad--;
                if (self.remainingScoresToLoad == 0)
                {
                    [self.personalBestLabel setText:@"Personal Best"];
                }
            }];
        }
        else
        {
            NSLog(@"todo, remove this NSLog: %@ bestScoreRequest is nil", scoreCategory);
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
                    NSLog(@"todo, remove this NSLog: totalScoreRequest loadScoresWithCompletionHandler error: %@", error);
                }
                GKScore* currentScore = [scoreCategory isEqualToString:@"org.teamrun.TotalRawMiles"]
                                      ? categoryToCurrentScore[@"org.teamrun.SingleRunRawMiles"]
                                      : categoryToCurrentScore[@"org.teamrun.SingleRunTeamMiles"];
                
                GKScore* totalScore = [[GKScore alloc] initWithCategory:scoreCategory];
                totalScore.value = currentScore.value; // temporarily set to just the current score
                totalScore.context = 0;
                
                if (scores != nil && scores.count > 0)
                {
                    totalScore.value += ((GKScore*)scores[0]).value;
                }
                
                [totalScore reportScoreWithCompletionHandler:^(NSError *error) {
                    if (error != nil) NSLog(@"todo, remove this NSLog: reportScoreWithCompletionHandler error: %@", error);
                    // game center will automatically resend the score later
                }];
                
                NSString* formattedScore = truncateToTwoDecimals(totalScore.value/100.0);
                
                if ([scoreCategory isEqualToString:@"org.teamrun.TotalRawMiles"])
                {
                    [self.totalRawMilesLabel setText:[[NSString alloc] initWithFormat:@"%@ total miles", formattedScore]];
                }
                else
                {
                    [self.totalTeamMilesLabel setText:[[NSString alloc] initWithFormat:@"%@ total team miles", formattedScore]];
                }
                
                self.remainingScoresToLoad--;
                if (self.remainingScoresToLoad == 0)
                {
                    // this whole process is super fast and the user probably will never see the original title "Personal Best (Loading...)"
                    [self.personalBestLabel setText:@"Personal Best"];
                }
            }];
        }
        else
        {
            NSLog(@"todo, remove this NSLog: totalScoreRequest is nil");
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
        if (error != nil) NSLog(@"todo, remove this NSLog: reportScoreWithCompletionHandler error: %@", error);
        // game center will automatically resend the score later
        // todo: test that this really is automatically resent
    }];
    
    categoryToCurrentScore[category]=scoreReporter;
}
@end
