//
//  ViewController.m
//  CustomCameraDemo
//
//  Created by User on 2019/7/30.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "CareraViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
  btn.frame = CGRectMake(0, 0, 300, 50);
  btn.center = self.view.center;
  [self.view addSubview:btn];
  [btn setTitle:@"跳转到照相机界面" forState:UIControlStateNormal];
  [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];

  [btn addTarget:self
          action:@selector(onCameraBtnTouch)
forControlEvents:UIControlEventTouchUpInside];
}

- (void)onCameraBtnTouch {
  CareraViewController *cameraVC = [[CareraViewController alloc] init];
  [self presentViewController:cameraVC animated:YES completion:nil];
}

@end
