//
//  ViewController.m
//  PaintByMetalDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "PaintingViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
}

#pragma mark - UI

- (void)setupUI {
  self.title = @"绘图demo";
  
  UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  [nextBtn setTitle:@"进入绘图" forState:UIControlStateNormal];
  [nextBtn addTarget:self action:@selector(onNextButtonTouch) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:nextBtn];
  nextBtn.frame = CGRectMake(0, 0, 300, 50);
  nextBtn.center = self.view.center;
}

#pragma mark - Button Action

- (void)onNextButtonTouch {
  PaintingViewController *paintVC = [[PaintingViewController alloc] init];
  [self.navigationController pushViewController:paintVC animated:YES];
}

@end
