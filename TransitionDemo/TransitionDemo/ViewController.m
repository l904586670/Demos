//
//  ViewController.m
//  TransitionDemo
//
//  Created by User on 2019/7/11.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "NavSecondViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  

  self.view.backgroundColor = [UIColor whiteColor];
  self.title = @"rootVC";
  

  [self btnWithAction:@selector(onNext)];
  
}

- (UIButton *)btnWithAction:(SEL)action {
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
  btn.frame = CGRectMake(0, 0, 200, 50);
  [btn setTitle:@"跳转到下个控制器" forState:UIControlStateNormal];
  btn.backgroundColor = [UIColor blueColor];
  [self.view addSubview:btn];
  btn.center = self.view.center;
  
  [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  
  return btn;
}

- (void)onNext {
  NavSecondViewController *secondVC = [[NavSecondViewController alloc] init];
  [self.navigationController pushViewController:secondVC animated:YES];
}


@end
