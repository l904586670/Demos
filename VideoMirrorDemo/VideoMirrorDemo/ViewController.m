//
//  ViewController.m
//  VideoMirrorDemo
//
//  Created by User on 2019/8/9.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "MirrorViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeInfoLight];
  [self.view addSubview:btn];
  btn.center = self.view.center;
  
  [btn addTarget:self action:@selector(onMirrorButtonTouch) forControlEvents:UIControlEventTouchUpInside];
  
}

- (void)onMirrorButtonTouch {
  MirrorViewController *mirrorVC = [[MirrorViewController alloc] init];
  [self presentViewController:mirrorVC animated:YES completion:nil];
}

@end
