//
//  TeamRunSettingsViewController.m
//  teamrun
//
//  Created by John DiMatteo on 4/29/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunSettingsViewController.h"

@interface TeamRunSettingsViewController ()

- (IBAction)doneChangingSettings;

@property (weak, nonatomic) IBOutlet UITextField *minutesBetweenNotificicationsTextField;
@property (weak, nonatomic) IBOutlet UITextField *secondsBetweenNotificationsTextField;
@property (weak, nonatomic) IBOutlet UITextField *targetMilePaceMinutes;
@property (weak, nonatomic) IBOutlet UITextField *targetMilePaceSeconds;

-(void)doneWithNumberPad;

@end

@implementation TeamRunSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    UIToolbar* dismissKeypadToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    dismissKeypadToolbar.barStyle = UIBarStyleBlackTranslucent;
    dismissKeypadToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)],
                           nil];
    [dismissKeypadToolbar sizeToFit];
    _minutesBetweenNotificicationsTextField.inputAccessoryView = dismissKeypadToolbar;
    _secondsBetweenNotificationsTextField.inputAccessoryView = dismissKeypadToolbar;
    _targetMilePaceMinutes.inputAccessoryView = dismissKeypadToolbar;
    _targetMilePaceSeconds.inputAccessoryView = dismissKeypadToolbar;
}

-(void)doneWithNumberPad
{
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneChangingSettings
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
