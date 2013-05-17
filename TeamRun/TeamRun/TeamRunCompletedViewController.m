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
@property (weak, nonatomic) IBOutlet UILabel *totalTeamRunMilesLabel;

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
    [self.currentRunRawMilesLabel setText:truncateToTwoDecimals(rawMiles)];
    [self.currentRunTimeLabel setText:[NSString stringWithFormat:@"%.2d:%.2d", seconds / 60, seconds % 60]];
    [self.currentRunTeamMilesLabel setText:truncateToTwoDecimals(teamMiles)];
    
    NSMutableDictionary* categoryToCurrentScore = [NSMutableDictionary dictionaryWithCapacity:3];
    [self reportScore:rawMiles*100 forLeaderboardID:@"org.teamrun.SingleRunRawMiles" addTo:categoryToCurrentScore];
    [self reportScore:teamMiles*100 forLeaderboardID:@"org.teamrun.SingleRunTeamMiles" addTo:categoryToCurrentScore];
    [self reportScore:seconds forLeaderboardID:@"org.teamrun.SingleRunSeconds" addTo:categoryToCurrentScore];
    
    // todo: populate pace label and submit pace score
    
    NSArray* currentPlayer = @[[GKLocalPlayer localPlayer].playerID];
    
    NSArray* scoreCateogries = @[@"org.teamrun.SingleRunRawMiles", @"org.teamrun.SingleRunTeamMiles", @"org.teamrun.SingleRunSeconds"];
    
    self.remainingScoresToLoad = scoreCateogries.count;
    
    for (NSString* scoreCategory in scoreCateogries)
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
                    NSLog(@"todo, remove this NSLog: loadScoresWithCompletionHandler error: %@", error);
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
                        if ([scoreCategory isEqualToString:@"org.teamrun.SingleRunRawMiles"])
                        {
                            [self.bestRunRawMilesLabel setText:personalBest.formattedValue];
                        }
                        else if ([scoreCategory isEqualToString:@"org.teamrun.SingleRunTeamMiles"])
                        {
                            [self.bestRunTeamMilesLabel setText:personalBest.formattedValue];
                        }
                        else if ([scoreCategory isEqualToString:@"org.teamrun.SingleRunSeconds"])
                        {
                            [self.bestRunTimeLabel setText:personalBest.formattedValue];
                        }
                    }
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
            NSLog(@"todo, remove this NSLog: bestScoreRequest is nil");
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
