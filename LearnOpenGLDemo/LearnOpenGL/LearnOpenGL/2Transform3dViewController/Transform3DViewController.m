//
//  Transfrom3DViewController.m
//  LearnOpenGL
//
//  Created by User on 2019/7/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "Transform3DViewController.h"

#import "TransformGLView.h"

@interface Transform3DViewController ()

@property (nonatomic, strong) TransformGLView *glTransformView;

@end

@implementation Transform3DViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);

  CGRect contentFrame = CGRectMake(0, posY, screenSize.width, screenSize.height - posY);
  
  TransformGLView *glView = [[TransformGLView alloc] initWithFrame:contentFrame];
  [self.view addSubview:glView];
  _glTransformView = glView;
  
  
  UISwitch *swt = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
  [swt addTarget:self action:@selector(onSwicth:) forControlEvents:UIControlEventValueChanged];
  UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:swt];
  self.navigationItem.rightBarButtonItem = barBtn;
}

- (void)onSwicth:(UISwitch *)sender {
  if (sender.on) {
    [self.glTransformView start];
  } else {
    [self.glTransformView end];
  }
}

@end
