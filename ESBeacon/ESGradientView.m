//
//  ESGradientView.m
//  ESBeacon
//
//  Created by Enamel Systems on 2013/12/31.
//  Copyright (c) 2014 Enamel Systems. All rights reserved.
//

#import "ESGradientView.h"
#import "UIColor-RGB.h"

//#define START_COLOR    RGB( 91, 156, 187)
#define START_COLOR    RGB( 81, 146, 187)
#define END_COLOR      RGB(143, 201, 213)

@implementation ESGradientView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self gradientLayer];
    }
    return self;
}

- (void)gradientLayer
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.frame;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[START_COLOR CGColor],
                       (id)[END_COLOR CGColor],
                       nil];
    [gradient setStartPoint:CGPointMake(0.5, 0.0)];
    [gradient setEndPoint:CGPointMake(0.5, 1.0)];
    [self.layer insertSublayer:gradient atIndex:0];
}

@end
