//
//  NavThirdViewController.m
//  TransitionDemo
//
//  Created by User on 2019/7/11.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "NavThirdViewController.h"

@interface NavThirdViewController () <UINavigationControllerDelegate>

@end

@implementation NavThirdViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  

  self.title = @"navThirdVC";
  self.view.backgroundColor = [UIColor blueColor];
  
  [self btnWithAction:@selector(onNext)];
}

- (UIButton *)btnWithAction:(SEL)action {
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
  btn.frame = CGRectMake(0, 0, 200, 50);
  [btn setTitle:@"返回上个控制器" forState:UIControlStateNormal];
  btn.backgroundColor = [UIColor redColor];
  [self.view addSubview:btn];
  btn.center = self.view.center;
  
  [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  
  return btn;
}

- (void)onNext {
  self.navigationController.delegate = self;
  
  [self.navigationController popViewControllerAnimated:YES];
}


@end
