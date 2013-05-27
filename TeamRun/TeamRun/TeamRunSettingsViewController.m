//
//  TeamRunSettingsViewController.m
//  teamrun
//
//  Created by John DiMatteo on 4/29/13.
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

#import "TeamRunSettingsViewController.h"
#import "TeamRunSettings.h"

#import <QuartzCore/QuartzCore.h>

@interface TeamRunSettingsViewController ()

- (IBAction)doneChangingSettings;

@property (weak, nonatomic) IBOutlet UITextField *minutesBetweenNotificationsTextField;
@property (weak, nonatomic) IBOutlet UITextField *secondsBetweenNotificationsTextField;

@property (weak, nonatomic) IBOutlet UITextField *targetMilePaceMinutesTextField;
@property (weak, nonatomic) IBOutlet UITextField *targetMilePaceSecondsTextField;

@property (weak, nonatomic) IBOutlet UISwitch *paceNotificationsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *relativePositionNotificationsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *targetMilePaceSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *multiplayerModeSwitch;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)updateEnabledFields;

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
    _targetMilePaceMinutesTextField.inputAccessoryView = dismissKeypadToolbar;
    _targetMilePaceSecondsTextField.inputAccessoryView = dismissKeypadToolbar;
    
    [_minutesBetweenNotificationsTextField setText:[NSString stringWithFormat:@"%d", [TeamRunSettings secondsBetweenNotifications]/60]];
    [_secondsBetweenNotificationsTextField setText:[NSString stringWithFormat:@"%d", [TeamRunSettings secondsBetweenNotifications]%60]];
    
    [_paceNotificationsSwitch setOn:[TeamRunSettings paceNotificationsEnabled]];
    [_relativePositionNotificationsSwitch setOn:[TeamRunSettings relativePositionNotificationsEnabled]];
    [_targetMilePaceSwitch setOn:[TeamRunSettings targetPaceEnabled]];
    
    
    [_targetMilePaceMinutesTextField setText:[NSString stringWithFormat:@"%d", [TeamRunSettings targetSecondsPerMile]/60]];
    [_targetMilePaceSecondsTextField setText:[NSString stringWithFormat:@"%d", [TeamRunSettings targetSecondsPerMile]%60]];
    
    [_multiplayerModeSwitch setOn:[TeamRunSettings multiplayerMode]];
        
    [self updateEnabledFields];
}

void enable(UITextField* textField, const bool enabled)
{
    textField.enabled = enabled;
    textField.alpha = enabled ? 1 : 0.6;
}

- (IBAction)updateEnabledFields
{
    const bool notificationsEnabled = _paceNotificationsSwitch.on || _relativePositionNotificationsSwitch.on;
    enable(_minutesBetweenNotificationsTextField, notificationsEnabled);
    enable(_secondsBetweenNotificationsTextField, notificationsEnabled);
    
    enable(_targetMilePaceMinutesTextField, _targetMilePaceSwitch.on);
    enable(_targetMilePaceSecondsTextField, _targetMilePaceSwitch.on);    
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

    [TeamRunSettings setTargetPaceEnabled: _targetMilePaceSwitch.isOn];
    
    [TeamRunSettings setTargetSecondsPerMile:[_targetMilePaceMinutesTextField.text intValue]*60 + [_targetMilePaceSecondsTextField.text intValue]];
    
    [TeamRunSettings setMultiplayerMode:_multiplayerModeSwitch.isOn];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
