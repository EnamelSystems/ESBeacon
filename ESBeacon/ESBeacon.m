//
//  ESBeacon.m
//  ESBeacon
//
//  Created by Enamel Systems on 2013/12/23.
//  Copyright (c) 2014 Enamel Systems. All rights reserved.
//

#import "ESBeacon.h"

@interface ESBeacon ()

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

    }
    return self;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
