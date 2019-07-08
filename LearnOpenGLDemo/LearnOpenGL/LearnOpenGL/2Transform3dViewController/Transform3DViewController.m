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

@end

@implementation Transform3DViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  
//  CGSize srceenSize = [UIScreen mainScreen].bounds.size;
//  CGRect frame = CGRectMake(0, 0, srceenSize.width, srceenSize.width);
  
  TransformGLView *glView = [[TransformGLView alloc] initWithFrame:self.contentRect];
  [self.view addSubview:glView];
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  glClearColor(0.95, 1.0, 1.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
}

#pragma mark - GLKViewControllerDelegate

- (void)glkViewControllerUpdate:(GLKViewController *)controller {
  
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause {
  
}

@end
