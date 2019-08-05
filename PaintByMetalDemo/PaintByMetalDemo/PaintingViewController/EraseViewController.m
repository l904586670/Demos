//
//  EraseViewController.m
//  PaintByMetalDemo
//
//  Created by User on 2019/8/5.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "EraseViewController.h"

#import "EraseMetalView.h"

@interface EraseViewController ()

@end

@implementation EraseViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
  if (@available(iOS 11.0, *)) {
    safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
  }
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  CGFloat height = screenSize.height - posY - safeAreaInsets.bottom;
  
  CGRect frame = CGRectMake(0, posY, screenSize.width, height);
  EraseMetalView *eraseView = [[EraseMetalView alloc] initWithFrame:frame];
  [self.view addSubview:eraseView];
}

@end
