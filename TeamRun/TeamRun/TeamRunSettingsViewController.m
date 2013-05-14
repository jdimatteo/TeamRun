//
//  TeamRunSettingsViewController.m
//  teamrun
//
//  Created by John DiMatteo on 4/29/13.
//  Copyright (c) 2013 John DiMatteo. All rights reserved.
//

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
@property (weak, nonatomic) IBOutlet UIView *notificationsSectionView;
@property (weak, nonatomic) IBOutlet UIView *targetPaceSectionView;
@property (weak, nonatomic) IBOutlet UIView *noteSectionView;
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
    
    _notificationsSectionView.layer.cornerRadius = 5;
    _notificationsSectionView.layer.masksToBounds = YES;
    _targetPaceSectionView.layer.cornerRadius = 5;
    _targetPaceSectionView.layer.masksToBounds = YES;
    _noteSectionView.layer.cornerRadius = 5;
    _noteSectionView.layer.masksToBounds = YES;
    
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
