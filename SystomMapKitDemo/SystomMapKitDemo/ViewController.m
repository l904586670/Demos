//
//  ViewController.m
//  SystomMapKitDemo
//
//  Created by User on 2019/7/23.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "MapBaseViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
}

#pragma mark - UI

- (void)setupUI {
  self.title = @"地图Demo";
  
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
  btn.frame = CGRectMake(0, 0, 300, 50);
  
  [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [btn setTitle:@"点击跳转到地图控制器" forState:UIControlStateNormal];
  [self.view addSubview:btn];
  btn.center = self.view.center;
  [btn addTarget:self
          action:@selector(onMapButtonTouch)
forControlEvents:UIControlEventTouchUpInside];
  
}

#pragma mark - Button Action

- (void)onMapButtonTouch {
  MapBaseViewController *mapVC = [[MapBaseViewController alloc] init];
  
  [self.navigationController pushViewController:mapVC animated:YES];
}

@end
