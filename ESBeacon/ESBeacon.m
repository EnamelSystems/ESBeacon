//
//  ESBeacon.m
//  ESBeacon
//
//  Created by Enamel Systems on 2013/12/23.
//  Copyright (c) 2014 Enamel Systems. All rights reserved.
//

#import "ESBeacon.h"

@interface ESBeacon ()
@property (nonatomic) CBPeripheralManager *peripheralManager;
@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic) ESBeaconMonitoringStatus monitoringStatus;
@property (nonatomic) BOOL isMonitoring;

@end

@implementation ESBeacon

+ (ESBeacon *)sharedManager
{
    static ESBeacon *sharedSingleton;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedSingleton = [[ESBeacon alloc] initSharedInstance];
    });

    return sharedSingleton;
}

- (id)initSharedInstance {
    self = [super init];
    if (self) {
        // Initialization of ESBeacon singleton.
        _monitoringStatus = kESBeaconMonitoringStatusDisabled;
        _isMonitoring = NO;
        
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        _regions = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    }
    return self;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark applicationDidBecomActive local notification handler.
- (void)applicationDidBecomeActive
{
    NSLog(@"Application did become active");
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(checkRegionStateTimer:) userInfo:nil repeats:NO];
}

- (void)checkRegionStateTimer:(NSTimer *)timer
{
    NSLog(@"timer called");

    // Update current region status when application did become active.
    for (ESBeaconRegion *region in self.regions) {
        if (region.isMonitoring) {
            NSLog(@"requestStateForRegion %@", region);
            [_locationManager requestStateForRegion:region];
        }
    }
}

- (BOOL)isMonitoringCapable
{
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        return NO;
    }
    if (_peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        return NO;
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        return NO;
    }
    return YES;
}

- (void)startMonitoring
{
    if (![self isMonitoringCapable]) {
        return;
    }
    if (_isMonitoring) {
        return;
    }
    
    NSLog(@"Start monitoring");
    for (ESBeaconRegion *region in self.regions) {
        [_locationManager startMonitoringForRegion:region];
        region.isMonitoring = YES;
    }
    
    _isMonitoring = YES;
    [self updateMonitoringStatus];
}

- (void)stopMonitoring
{
    NSLog(@"Stop monitoring");
    if (! _isMonitoring) {
        return;
    }
    for (ESBeaconRegion *region in self.regions) {
        [_locationManager stopMonitoringForRegion:region];
        [_locationManager stopRangingBeaconsInRegion:region];
        region.isMonitoring = NO;
    }

    _isMonitoring = NO;
    [self updateMonitoringStatus];
}

- (ESBeaconMonitoringStatus)getUpdatedMonitoringStatus
{
    if (! [self isMonitoringCapable]) {
        return kESBeaconMonitoringStatusDisabled;
    }
    if (_isMonitoring) {
        return kESBeaconMonitoringStatusMonitoring;
    } else {
        return kESBeaconMonitoringStatusStopped;
    }
}

- (void)updateMonitoringStatus
{
    ESBeaconMonitoringStatus currentStatus = self.monitoringStatus;
    ESBeaconMonitoringStatus newStatus = [self getUpdatedMonitoringStatus];
    
    if (currentStatus != newStatus) {
        self.monitoringStatus = newStatus;
        if ([_delegate respondsToSelector:@selector(didUpdateMonitoringStatus:)]) {
            [_delegate didUpdateMonitoringStatus:self.monitoringStatus];
        }
    }
}

- (void)requestUpdateForStatus
{
    if ([_delegate respondsToSelector:@selector(didUpdateMonitoringStatus:)]) {
        [_delegate didUpdateMonitoringStatus:self.monitoringStatus];
    }
    if ([_delegate respondsToSelector:@selector(didUpdatePeripheralState:)]) {
        [_delegate didUpdatePeripheralState:self.peripheralManager.state];
    }
    if ([_delegate respondsToSelector:@selector(didUpdateAuthorizationStatus:)]) {
        [_delegate didUpdateAuthorizationStatus:[CLLocationManager authorizationStatus]];
    }
}

- (void)startRanging:(ESBeaconRegion *)region
{
    NSLog(@"startRanging");
    [_locationManager startRangingBeaconsInRegion:region];
}

- (void)stopRanging:(ESBeaconRegion *)region
{
    NSLog(@"stopRanging");
    [_locationManager stopRangingBeaconsInRegion:region];
}

#pragma mark -
#pragma mark Region management
- (BOOL)registerRegion:(NSString *)UUIDString identifier:(NSString *)identifier rangingEnabled:(BOOL)rangingEnabled
{
    if ([self.regions count] >= kESBeaconRegionMax) {
        return NO;
    }
    
    ESBeaconRegion *region = [[ESBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] identifier:identifier];
    region.rangingEnabled = rangingEnabled;
    region.isMonitoring = NO;
    region.hasEntered = NO;
    region.isRanging = NO;
    [self.regions addObject:region];
    NSLog(@"Region registered: %@", region);

    return YES;
}

- (void)unregisterRegion:(NSUUID *)proximityUUID identifier:(NSString *)identifier
{
    ;
}

- (ESBeaconRegion *)lookupRegion:(CLBeaconRegion *)region
{
    for (ESBeaconRegion *esRegion in _regions) {
        if ([esRegion.proximityUUID.UUIDString isEqualToString:region.proximityUUID.UUIDString] &&
            [esRegion.identifier isEqualToString:region.identifier] &&
            esRegion.major == region.major &&
            esRegion.minor == region.minor) {
            return esRegion;
        }
    }
    return nil;
}

- (void)enterRegionNotification:(ESBeaconRegion *)region
{
    // LocalNotification.
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        //notification.alertBody = region.proximityUUID.UUIDString;
        notification.alertBody = region.identifier;
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

- (void)enterRegion:(CLBeaconRegion *)region
{
    NSLog(@"enterRegion called");
    
    ESBeaconRegion *esRegion = [self lookupRegion:region];
    if (! esRegion) {
        NSLog(@"enterRegion: Can't find ESBeaconRegion");
        return;
    }
        
    if (! esRegion.hasEntered) {
        if (esRegion.rangingEnabled) {
            [self startRanging:esRegion];
        }
        [self enterRegionNotification:esRegion];
        esRegion.hasEntered = YES;
    }
}

- (void)exitRegion:(CLBeaconRegion *)region
{
    NSLog(@"exitRegion called");
    
    ESBeaconRegion *esRegion = [self lookupRegion:region];
    if (! esRegion) {
        NSLog(@"exitRegion: Can't find ESBeaconRegion");
        return;
    }

    if (esRegion.hasEntered) {
        if (esRegion.rangingEnabled) {
            [self stopRanging:esRegion];
        }
        esRegion.hasEntered = NO;
    }
}

#pragma mark -
#pragma mark CBPeripheralManagerDelegate
- (NSString *)peripheralStateString:(CBPeripheralManagerState)state
{
    switch (state) {
        case CBPeripheralManagerStatePoweredOn:
            return @"On";
        case CBPeripheralManagerStatePoweredOff:
            return @"Off";
        case CBPeripheralManagerStateResetting:
            return @"Resetting";
        case CBPeripheralManagerStateUnauthorized:
            return @"Unauthorized";
        case CBPeripheralManagerStateUnknown:
            return @"Unknown";
        case CBPeripheralManagerStateUnsupported:
            return @"Unsupported";
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState: %@", [self peripheralStateString:peripheral.state]);

    if ([_delegate respondsToSelector:@selector(didUpdatePeripheralState:)]) {
        [_delegate didUpdatePeripheralState:peripheral.state];
    }

    [self updateMonitoringStatus];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate (Responding to Region Events)
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"didStartMonitoringForRegion %@", region);
    [self.locationManager requestStateForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Enter the region: %@", region);
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self enterRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Exit the region: %@", region);
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self exitRegion:(CLBeaconRegion *)region];
    }
}

- (NSString *)regionStateString:(CLRegionState)state
{
    switch (state) {
        case CLRegionStateInside:
            return @"inside";
        case CLRegionStateOutside:
            return @"outside";
        case CLRegionStateUnknown:
            return @"unknown";
    }
    return @"";
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSLog(@"didDetermineState %@ %@", [self regionStateString:state], region);

    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        switch (state) {
        case CLRegionStateInside:
            [self enterRegion:(CLBeaconRegion *)region];
            break;
        case CLRegionStateOutside:
        case CLRegionStateUnknown:
            [self exitRegion:(CLBeaconRegion *)region];
            break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"monitoringDidFailForRegion %@", error);
}

#pragma mark CLLocationManagerDelegate (Responding to Ranging Events)
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (! beacons) {
        NSLog(@"didRangeBeacons: count 0");
    } else {
        NSLog(@"didRangeBeacons: count %lu", (unsigned long)[beacons count]);
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"rangingBeaconsDidFailForRegion: %@", error);
    
    ESBeaconRegion *esRegion = [self lookupRegion:region];
    if (!esRegion) {
        NSLog(@"exitRegion: Can't find ESBeaconRegion for %@", region);
        return;
    }
    [self stopRanging:esRegion];
}

#pragma mark CLLocationManagerDelegate (Responding to Authorization Changes)
- (NSString *)locationAuthorizationStatusString:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            return @"Not determined";
        case kCLAuthorizationStatusRestricted:
            return @"Restricted";
        case kCLAuthorizationStatusDenied:
            return @"Denied";
        case kCLAuthorizationStatusAuthorized:
            return @"Authorized";
    }
    return @"";
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"locationManager didChangeAuthorizationStatus %@", [self locationAuthorizationStatusString:status]);

    if ([_delegate respondsToSelector:@selector(didUpdateAuthorizationStatus:)]) {
        [_delegate didUpdateAuthorizationStatus:status];
    }

    [self updateMonitoringStatus];
}

@end
