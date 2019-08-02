//
//  PaintingViewController.m
//  PaintByMetalDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "PaintingViewController.h"

#import "PaintingView.h"
#import "PaintMetalView.h"

@interface PaintingViewController ()

@end

@implementation PaintingViewController

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
  
  PaintMetalView *paintView = [[PaintMetalView alloc] initWithFrame:frame];
  [self.view addSubview:paintView];
}


@end
