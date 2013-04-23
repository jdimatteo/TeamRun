//
//  ConfigureRunViewController.m
//  teamrun
//
//  Created by John DiMatteo on 12/29/12.
//  Copyright (c) 2012 John DiMatteo. All rights reserved.
//

#import "ConfigureRunViewController.h"

@interface ConfigureRunViewController ()
- (IBAction)runConfigured:(id)sender;

@end

@implementation ConfigureRunViewController

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
    
    NSLog(@"ConfigureRunViewController did load");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)runConfigured:(id)sender {
    NSLog(@"run configured...");
    
    // todo: consider making the model a shared singleton, and setting
    // the configured values there
        
    // todo: get the first view to present the GKMatchmakerViewController
}
@end
