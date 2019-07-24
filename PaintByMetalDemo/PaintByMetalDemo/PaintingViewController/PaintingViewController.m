//
//  PaintingViewController.m
//  PaintByMetalDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "PaintingViewController.h"

@interface PaintingViewController ()

@end

@implementation PaintingViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
  if (@available(iOS 11.0, *)) {
    safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
  }
  
  
  
  
}


@end
