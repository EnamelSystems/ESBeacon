//
//  ESBeaconViewController.h
//  ESBeacon
//
//  Created by Enamel Systems on 2013/12/23.
//  Copyright (c) 2014 Enamel Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESBeacon.h"

@interface ESBeaconViewController : UIViewController <ESBeaconDelegate>
@property (weak, nonatomic) IBOutlet UIButton *monitoringButton;
@property (weak, nonatomic) IBOutlet UILabel *bluetoothLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorizationLabel;
- (IBAction)monitoringButtonPressed:(id)sender;
@end
