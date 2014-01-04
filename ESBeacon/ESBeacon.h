//
//  ESBeacon.h
//  ESBeacon
//
//  Created by Enamel Systems on 2013/12/23.
//  Copyright (c) 2014 Enamel Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;
@import CoreBluetooth;

#import "ESBeaconRegion.h"

typedef enum {
        kESBeaconMonitoringStatusDisabled,
        kESBeaconMonitoringStatusStopped,
        kESBeaconMonitoringStatusMonitoring
} ESBeaconMonitoringStatus;

#define kESBeaconRegionMax     20

@protocol ESBeaconDelegate <NSObject>
@optional
- (void)didUpdatePeripheralState:(CBPeripheralManagerState)state;
- (void)didUpdateAuthorizationStatus:(CLAuthorizationStatus)status;
- (void)didUpdateMonitoringStatus:(ESBeaconMonitoringStatus)status;

- (void)didUpdateRegionEnterOrExit:(ESBeaconRegion *)region;
- (void)didRangeBeacons:(ESBeaconRegion *)region;
@end

@interface ESBeacon : NSObject <CBPeripheralManagerDelegate, CLLocationManagerDelegate>
@property (nonatomic) NSMutableArray *regions;
@property (nonatomic, weak) id<ESBeaconDelegate> delegate;

+ (ESBeacon *)sharedManager;
- (void)requestUpdateForStatus;
- (void)startMonitoringAllRegion;
- (void)stopMonitoringAllRegion;
- (ESBeaconRegion *)registerRegion:(NSString *)UUIDString identifier:(NSString *)identifier;
- (ESBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major identifier:(NSString *)identifier;
- (ESBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier;
@end
