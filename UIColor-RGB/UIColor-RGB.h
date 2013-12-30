//
//  UIColor-RGB.h
//  Utility macro for creating RGB/RGBA UIColor.
//
//  Created by Enamel Systems on 2013/11/28.
//  Copyright (c) 2013 Enamel Systems. All rights reserved.
//

#ifndef UIColor_RGB_h
#define UIColor_RGB_h

#define RGB(r, g, b)      [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define RGBA(r, g, b, a)  [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)/255.0]

#endif
