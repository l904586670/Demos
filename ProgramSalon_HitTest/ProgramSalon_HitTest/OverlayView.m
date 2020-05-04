//
//  EView.m
//  ProgramSalon_HitTest
//
//  Created by Trevor on 16/06/26.
//  Copyright © 2016年 Yiqux. All rights reserved.
//

#import "OverlayView.h"

@implementation OverlayView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *hitTestView = [super hitTest:point withEvent:event];
  if (hitTestView == self) {
    hitTestView = nil;
  }
  return hitTestView;
}

@end
