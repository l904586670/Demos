//
//  UIColor+Tool.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/6/8.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "UIColor+Tool.h"

@implementation UIColor (Tool)

-(BOOL)compareColor:(UIColor *)secondColor {
    if (CGColorEqualToColor(self.CGColor, secondColor.CGColor)) {
        return YES;
    }
    else {
        return NO;
    }
}


@end
