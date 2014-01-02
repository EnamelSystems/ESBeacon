//
//  ESBeaconViewController.m
//  ESBeacon
//
//  Created by Enamel Systems on 2013/12/23.
//  Copyright (c) 2014 Enamel Systems. All rights reserved.
//

#import "ESBeaconViewController.h"
#import "ESBeacon.h"

// Using Estimote UUID for testing.
#define kBeaconUUID    @"B9407F30-F5F8-466E-AFF9-25556B57FE6D"
#define kIdentifier    @"Enamel Systems"

@interface ESBeaconViewController ()
@property (nonatomic, weak) ESBeacon *beacon;
@property (nonatomic) ESBeaconMonitoringStatus monitoringStatus;
@end

@implementation ESBeaconViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.beacon = [ESBeacon sharedManager];
    self.beacon.delegate = self;
    [self.beacon registerRegion:kBeaconUUID identifier:kIdentifier rangingEnabled:YES];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.beacon requestUpdateForStatus];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)monitoringButtonPressed:(id)sender {
    NSLog(@"Monitoring button pressed");
    if (_monitoringStatus == kESBeaconMonitoringStatusStopped) {
        [self.beacon startMonitoring];
    } else if (_monitoringStatus == kESBeaconMonitoringStatusMonitoring) {
        [self.beacon stopMonitoring];
    }
}

#pragma mark -
#pragma mark ESBeaconDelegate
- (void)didUpdateMonitoringStatus:(ESBeaconMonitoringStatus)status
{
    _monitoringStatus = status;
    
    switch (status) {
        case kESBeaconMonitoringStatusDisabled:
            [self.monitoringButton setTitle:@"Disabled" forState:UIControlStateNormal];
            [self.monitoringButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.monitoringButton.enabled = NO;
            break;
        case kESBeaconMonitoringStatusStopped:
            [self.monitoringButton setTitle:@"Start Monitoring" forState:UIControlStateNormal];
            [self.monitoringButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.monitoringButton.enabled = YES;
            break;
        case kESBeaconMonitoringStatusMonitoring:
            [self.monitoringButton setTitle:@"Monitoring (Press to Stop)" forState:UIControlStateNormal];
            [self.monitoringButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            self.monitoringButton.enabled = YES;
            break;
    }
}

- (void)didUpdatePeripheralState:(CBPeripheralManagerState)state
{
    switch (state) {
        case CBPeripheralManagerStateUnsupported:
            self.bluetoothLabel.text = @"Bluetooth: Unsupported";
            break;
        case CBPeripheralManagerStatePoweredOn:
            self.bluetoothLabel.text = @"Bluetooth: On";
            break;
        case CBPeripheralManagerStatePoweredOff:
            self.bluetoothLabel.text = @"Bluetooth: Off";
            break;
        case CBPeripheralManagerStateUnauthorized:
            self.bluetoothLabel.text = @"Bluetooth: Unauthorized";
            break;
        case CBPeripheralManagerStateResetting:
            self.bluetoothLabel.text = @"Bluetooth: Resetting";
            break;
        case CBPeripheralManagerStateUnknown:
            self.bluetoothLabel.text = @"Bluetooth: Unknown";
            break;
    }
}

- (void)didUpdateAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            self.authorizationLabel.text = @"Authorization: Not Determined";
            break;
        case kCLAuthorizationStatusRestricted:
            self.authorizationLabel.text = @"Authorization: Restricted";
            break;
        case kCLAuthorizationStatusDenied:
            self.authorizationLabel.text = @"Authorization: Denied";
            break;
        case kCLAuthorizationStatusAuthorized:
            self.authorizationLabel.text = @"Authorization: On";
            break;
    }
}

@end
