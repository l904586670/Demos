//
//  UIViewController+Utils.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/27.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "UIViewController+Utils.h"

@implementation UIViewController (Utils)

- (UIEdgeInsets)safeAreaEdgeInsets {
  if (@available(iOS 11.0, *)) {
    return [UIApplication sharedApplication].delegate.window.safeAreaInsets;
  } else {
    // Fallback on earlier versions
    return UIEdgeInsetsZero;
  }
}

- (CGSize)screenSize {
  return [UIScreen mainScreen].bounds.size;
}

- (CGRect)contentRect {
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  CGFloat height = self.screenSize.height - posY - self.safeAreaEdgeInsets.bottom;
  return CGRectMake(0, posY, self.screenSize.width, height);
}

@end
