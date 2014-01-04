//
//  ESBeaconRegion.m
//  ESBeacon
//
//  Created by Enamel Systems on 2013/12/31.
//  Copyright (c) 2014 Enamel Systems. All rights reserved.
//

#import "ESBeaconRegion.h"

@implementation ESBeaconRegion

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)clearFlags
{
    self.rangingEnabled = NO;
    self.isMonitoring = NO;
    self.hasEntered = NO;
    self.isRanging = NO;
    self.beacons = nil;
}

@end
