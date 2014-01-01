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

typedef enum {
        kESBeaconMonitoringStatusDisabled,
        kESBeaconMonitoringStatusStopped,
        kESBeaconMonitoringStatusMonitoring
} ESBeaconMonitoringStatus;

#define kESBeaconRegionMax     20

@protocol ESBeaconDelegate <NSObject>
@optional
- (void)didUpdateMonitoringStatus:(ESBeaconMonitoringStatus)status;
- (void)didUpdatePeripheralState:(CBPeripheralManagerState)state;
- (void)didUpdateAuthorizationStatus:(CLAuthorizationStatus)status;
@end

@interface ESBeacon : NSObject <CLLocationManagerDelegate, CBPeripheralManagerDelegate>
@property (nonatomic, weak) id<ESBeaconDelegate> delegate;
@property (nonatomic) NSMutableArray *regions;

+ (ESBeacon *)sharedManager;
- (void)requestUpdateForStatus;
- (void)startMonitoring;
- (void)stopMonitoring;

- (BOOL)registerRegion:(NSString *)UUIDString identifier:(NSString *)identifier rangingEnabled:(BOOL)rangingEnabled;
@end
