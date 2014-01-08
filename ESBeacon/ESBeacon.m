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
@property (nonatomic) BOOL monitoringEnabled;
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
        _monitoringEnabled = NO;
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
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(checkRegionState:) userInfo:nil repeats:NO];
}

- (void)checkRegionState:(NSTimer *)timer
{
    // Update current region status when application did become active.
    for (ESBeaconRegion *region in self.regions) {
        if (region.isMonitoring) {
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
    self.monitoringEnabled = YES;
    [self startMonitoringAllRegion];
}

- (void)stopMonitoring
{
    self.monitoringEnabled = NO;
    [self stopMonitoringAllRegion];
}

- (void)startMonitoringAllRegion
{
    if (! self.monitoringEnabled)
        return;
    if (! [self isMonitoringCapable])
        return;
    if (self.isMonitoring) {
        return;
    }
    NSLog(@"Start monitoring");
    for (ESBeaconRegion *region in self.regions) {
        [self startMonitoringRegion:region];
    }
    self.isMonitoring = YES;
    [self updateMonitoringStatus];
}

- (void)startMonitoringRegion:(ESBeaconRegion *)region
{
    [_locationManager startMonitoringForRegion:region];
    region.isMonitoring = YES;
}

- (void)startMonitoringRegionTry:(NSTimer *)timer
{
    [self startMonitoringRegion:(ESBeaconRegion *)timer.userInfo];
}

- (void)stopMonitoringAllRegion
{
    if (! self.isMonitoring) {
        return;
    }
    NSLog(@"Stop monitoring");
    for (ESBeaconRegion *region in self.regions) {
        [self stopMonitoringRegion:region];
    }
    self.isMonitoring = NO;
    [self updateMonitoringStatus];
}

- (void)stopMonitoringRegion:(ESBeaconRegion *)region
{
    [_locationManager stopMonitoringForRegion:region];
    [self stopRanging:region];
    region.isMonitoring = NO;
    if (region.hasEntered) {
        region.hasEntered = NO;
        if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
            [_delegate didUpdateRegionEnterOrExit:region];
        }
    }
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
    if (! region.isRanging) {
        [_locationManager startRangingBeaconsInRegion:region];
        region.isRanging = YES;
    }
}

- (void)stopRanging:(ESBeaconRegion *)region
{
    NSLog(@"stopRanging");
    if (region.isRanging) {
        [_locationManager stopRangingBeaconsInRegion:region];
        region.beacons = nil;
        region.isRanging = NO;
    }
}

#pragma mark -
#pragma mark Region management
- (ESBeaconRegion *)registerRegion:(NSString *)UUIDString identifier:(NSString *)identifier
{
    if ([self.regions count] >= kESBeaconRegionMax) {
        return nil;
    }
    ESBeaconRegion *region = [[ESBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] identifier:identifier];
    [region clearFlags];
    [self.regions addObject:region];
    return region;
}

- (ESBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major identifier:(NSString *)identifier
{
    if ([self.regions count] >= kESBeaconRegionMax) {
        return nil;
    }
    ESBeaconRegion *region = [[ESBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major identifier:identifier];
    [region clearFlags];
    [self.regions addObject:region];
    return region;
}

- (ESBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier
{
    if ([self.regions count] >= kESBeaconRegionMax) {
        return nil;
    }
    ESBeaconRegion *region = [[ESBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major minor:minor identifier:identifier];
    [region clearFlags];
    [self.regions addObject:region];
    return region;
}

- (void)unregisterAllRegion
{
    [self stopMonitoring];
    [self.regions removeAllObjects];
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

- (void)enterRegion:(CLBeaconRegion *)region
{
    NSLog(@"enterRegion called");
    
    // Lookup ESBeaconRegion.
    ESBeaconRegion *esRegion = [self lookupRegion:region];
    if (! esRegion)
        return;
    
    // Already in the region.
    if (esRegion.hasEntered)
        return;

    // When ranging is enabled, start ranging.
    if (esRegion.rangingEnabled)
        [self startRanging:esRegion];

    // Mark as entered.
    esRegion.hasEntered = YES;
    if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
        [_delegate didUpdateRegionEnterOrExit:esRegion];
    }
}

- (void)exitRegion:(CLBeaconRegion *)region
{
    NSLog(@"exitRegion called");
    
    ESBeaconRegion *esRegion = [self lookupRegion:region];
    if (! esRegion)
        return;

    if (! esRegion.hasEntered)
        return;

    if (esRegion.rangingEnabled)
        [self stopRanging:esRegion];

    esRegion.hasEntered = NO;
    if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
        [_delegate didUpdateRegionEnterOrExit:esRegion];
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

    if ([self isMonitoringCapable]) {
        [self startMonitoringAllRegion];
    } else {
        [self stopMonitoringAllRegion];
    }
    
    if ([_delegate respondsToSelector:@selector(didUpdatePeripheralState:)]) {
        [_delegate didUpdatePeripheralState:peripheral.state];
    }

    [self updateMonitoringStatus];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate (Responding to Region Events)
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"didStartMonitoringForRegion:%@", region.identifier);
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        ESBeaconRegion *esBeacon = [self lookupRegion:(CLBeaconRegion *)region];
        if (esBeacon) {
            esBeacon.failCount = 0;
        }
    }

    [self.locationManager requestStateForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self enterRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
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
    NSLog(@"didDetermineState:%@(%@)", [self regionStateString:state], region.identifier);

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
    NSLog(@"monitoringDidFailForRegion:%@(%@)", region.identifier, error);
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        ESBeaconRegion *esRegion = [self lookupRegion:(CLBeaconRegion *)region];
        if (! esRegion)
            return;

        [self stopMonitoringRegion:esRegion];
        
        if (esRegion.failCount < ESBeaconRegionFailCountMax) {
            esRegion.failCount++;
            [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(startMonitoringRegionTry:) userInfo:esRegion repeats:NO];
        }
    }
}

#pragma mark CLLocationManagerDelegate (Responding to Ranging Events)
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    ESBeaconRegion *esRegion = [self lookupRegion:region];
    if (! esRegion)
        return;

    esRegion.beacons = beacons;
    
    if ([_delegate respondsToSelector:@selector(didRangeBeacons:)]) {
        [_delegate didRangeBeacons:esRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"rangingBeaconsDidFailForRegion:%@(%@)", region.identifier, error);
    
    ESBeaconRegion *esRegion = [self lookupRegion:region];
    if (! esRegion)
        return;

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
    NSLog(@"didChangeAuthorizationStatus:%@", [self locationAuthorizationStatusString:status]);

    if ([self isMonitoringCapable]) {
        [self startMonitoringAllRegion];
    } else {
        [self stopMonitoringAllRegion];
    }

    if ([_delegate respondsToSelector:@selector(didUpdateAuthorizationStatus:)]) {
        [_delegate didUpdateAuthorizationStatus:status];
    }

    [self updateMonitoringStatus];
}

@end
