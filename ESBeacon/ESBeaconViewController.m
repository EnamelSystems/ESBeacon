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
    ESBeaconRegion *region;

    region = [self.beacon registerRegion:kBeaconUUID identifier:kIdentifier];
    if (region) {
        region.rangingEnabled = YES;
    }

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
            //[self.monitoringButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.monitoringButton.enabled = NO;
            break;
        case kESBeaconMonitoringStatusStopped:
            [self.monitoringButton setTitle:@"Start Monitoring" forState:UIControlStateNormal];
            //[self.monitoringButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.monitoringButton.enabled = YES;
            break;
        case kESBeaconMonitoringStatusMonitoring:
            [self.monitoringButton setTitle:@"Monitoring (Press to Stop)" forState:UIControlStateNormal];
            //[self.monitoringButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            self.monitoringButton.enabled = YES;
            break;
    }
    
    [self.tableView reloadData];
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

- (void)didUpdateRegionEnterOrExit:(ESBeaconRegion *)region
{
    NSLog(@"didUpdateRegionEnterOrExit: delegate called");
    [_tableView reloadData];
}

- (void)didRangeBeacons:(ESBeaconRegion *)region
{
    NSLog(@"didRangeBeacons: delegate called");
    [_tableView reloadData];
}

#pragma mark -
#pragma mark UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.beacon.regions count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    ESBeaconRegion *region = [self.beacon.regions objectAtIndex:section];
    if (region) {
        if (region.beacons == nil) {
            return 0;
        } else {
            return [region.beacons count];
        }
    }
    return 0;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableHeaderCell"];
    ESBeaconRegion *region = [self.beacon.regions objectAtIndex:section];
    if (region) {
        UILabel *UUIDLabel = (UILabel *)[cell viewWithTag:1];
        UILabel *majorLabel = (UILabel *)[cell viewWithTag:2];
        UILabel *minorLabel = (UILabel *)[cell viewWithTag:3];
        UIImageView *monitoring = (UIImageView *)[cell viewWithTag:4];
        UIImageView *entered = (UIImageView *)[cell viewWithTag:5];
        UUIDLabel.adjustsFontSizeToFitWidth = YES;
        UUIDLabel.text = region.proximityUUID.UUIDString;
        if (region.major) {
            majorLabel.text = [NSString stringWithFormat:@"major: %@", region.major];
        } else {
            majorLabel.text = @"major: nil";
        }
        if (region.minor) {
            minorLabel.text = [NSString stringWithFormat:@"minor: %@", region.minor];
        } else {
            minorLabel.text = @"minor: nil";
        }
        if (region.isMonitoring) {
            monitoring.image = [UIImage imageNamed:@"green.png"];
        } else {
            monitoring.image = [UIImage imageNamed:@"red.png"];
        }
        if (region.hasEntered) {
            entered.image = [UIImage imageNamed:@"green.png"];
        } else {
            entered.image = [UIImage imageNamed:@"red.png"];
        }
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell= [tableView dequeueReusableCellWithIdentifier:@"tableViewCell"];

    ESBeaconRegion *region = [self.beacon.regions objectAtIndex:indexPath.section];
    if (region && region.beacons) {
        CLBeacon *beacon = [region.beacons objectAtIndex:indexPath.row];
        if (beacon) {
            UILabel *majorLabel = (UILabel *)[cell viewWithTag:1];
            UILabel *minorLabel = (UILabel *)[cell viewWithTag:2];
            UILabel *RSSILabel = (UILabel *)[cell viewWithTag:3];
            UILabel *accuracyLabel = (UILabel *)[cell viewWithTag:4];
            UILabel *proximityLabel = (UILabel *)[cell viewWithTag:5];
            majorLabel.text = [NSString stringWithFormat:@"major %@", beacon.major];
            minorLabel.text = [NSString stringWithFormat:@"minor %@", beacon.minor];
            RSSILabel.text = [NSString stringWithFormat:@"RSSI: %ld", (long)beacon.rssi];
            accuracyLabel.text = [NSString stringWithFormat:@"Accuracy: %f", beacon.accuracy];
            switch (beacon.proximity) {
                case CLProximityUnknown:
                    proximityLabel.text = @"Proximity: Unknown";
                    break;
                case CLProximityImmediate:
                    proximityLabel.text = @"Proximity: Immediate";
                    break;
                case CLProximityNear:
                    proximityLabel.text = @"Proximity: Near";
                    break;
                case CLProximityFar:
                    proximityLabel.text = @"Proximity: Far";
                    break;
            }
        }
    }
    
    return cell;
}

@end
