//
//  TeamRunSettingsViewController.m
//  teamrun
//
//  Created by John DiMatteo on 4/29/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

#import "TeamRunSettingsViewController.h"
#import "TeamRunSettings.h"

@interface TeamRunSettingsViewController ()

- (IBAction)doneChangingSettings;

@property (weak, nonatomic) IBOutlet UITextField *minutesBetweenNotificationsTextField;
@property (weak, nonatomic) IBOutlet UITextField *secondsBetweenNotificationsTextField;
@property (weak, nonatomic) IBOutlet UITextField *targetMilePaceMinutes;
@property (weak, nonatomic) IBOutlet UITextField *targetMilePaceSeconds;
@property (weak, nonatomic) IBOutlet UISwitch *paceNotificationsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *relativePositionNotificationsSwitch;

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
                           [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)],
                           nil];
    [dismissKeypadToolbar sizeToFit];
    _minutesBetweenNotificationsTextField.inputAccessoryView = dismissKeypadToolbar;
    _secondsBetweenNotificationsTextField.inputAccessoryView = dismissKeypadToolbar;
    _targetMilePaceMinutes.inputAccessoryView = dismissKeypadToolbar;
    _targetMilePaceSeconds.inputAccessoryView = dismissKeypadToolbar;
    
    [_minutesBetweenNotificationsTextField setText:[NSString stringWithFormat:@"%d", [TeamRunSettings secondsBetweenNotifications]/60]];
    [_secondsBetweenNotificationsTextField setText:[NSString stringWithFormat:@"%d", [TeamRunSettings secondsBetweenNotifications]%60]];
    
    [_paceNotificationsSwitch setOn:[TeamRunSettings paceNotificationsEnabled]];
    [_relativePositionNotificationsSwitch setOn:[TeamRunSettings relativePositionNotificationsEnabled]];
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
    [TeamRunSettings setSecondsBetweenNotifications:[_minutesBetweenNotificationsTextField.text intValue]*60 + [_secondsBetweenNotificationsTextField.text intValue]];
    
    [TeamRunSettings setPaceNotificationsEnabled: _paceNotificationsSwitch.isOn];
    [TeamRunSettings setRelativePositionNotificationsEnabled: _relativePositionNotificationsSwitch.isOn];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
