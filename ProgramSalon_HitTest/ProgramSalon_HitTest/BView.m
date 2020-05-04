//
//  BView.m
//  ProgramSalon_HitTest
//
//  Created by Trevor on 16/06/26.
//  Copyright © 2016年 Yiqux. All rights reserved.
//

#import "BView.h"

@implementation BView

/*- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"进入B_View---hitTest withEvent ---");
    UIView * view = [super hitTest:point withEvent:event];
    NSLog(@"离开B_View---hitTest withEvent ---hitTestView:%@",view);
    return view;
}*/

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  if (!self.isUserInteractionEnabled || self.isHidden || self.alpha <= 0.01) {
    return nil;
  }
  CGRect touchRect = CGRectInset(self.bounds, -10, -50);
  if (CGRectContainsPoint(touchRect, point)) {
    for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
      CGPoint convertedPoint = [subview convertPoint:point fromView:self];
      UIView *hitTestView = [subview hitTest:convertedPoint withEvent:event];
      if (hitTestView) {
        return hitTestView;
      }
    }
    return self;
  }
  return nil;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    NSLog(@"B_view---pointInside withEvent ---");
    BOOL isInside = [super pointInside:point withEvent:event];
    NSLog(@"B_view---pointInside withEvent --- isInside:%d",isInside);
    return isInside;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"B_touchesBegan");
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    NSLog(@"B_touchesMoved");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    NSLog(@"B_touchesEnded");
}


@end
