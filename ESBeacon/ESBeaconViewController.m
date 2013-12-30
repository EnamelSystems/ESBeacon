//
//  ESBeaconViewController.m
//  ESBeacon
//
//  Created by Enamel Systems on 2013/12/23.
//  Copyright (c) 2014 Enamel Systems. All rights reserved.
//

#import "ESBeaconViewController.h"
#import "ESBeacon.h"
#import "UIColor-RGB.h"

@interface ESBeaconViewController ()
@property (nonatomic, weak) ESBeacon *beacon;
@end

@implementation ESBeaconViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.view.backgroundColor = RGB(91, 156, 187);
    self.view.backgroundColor = RGB(143, 201, 213);
    
    self.beacon = [ESBeacon sharedManager];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
