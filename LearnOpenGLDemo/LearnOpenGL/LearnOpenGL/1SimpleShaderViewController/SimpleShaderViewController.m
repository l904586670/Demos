//
//  SimpleShaderViewController.m
//  LearnOpenGL
//
//  Created by User on 2019/7/6.
//  Copyright © 2019 Rock. All rights reserved.
//

// https://learnopengl-cn.github.io/01%20Getting%20started/04%20Hello%20Triangle/#_3

#import "SimpleShaderViewController.h"

#import "CustomGLView.h"

@interface SimpleShaderViewController ()

@end

@implementation SimpleShaderViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  
  CGSize srceenSize = [UIScreen mainScreen].bounds.size;
  CGRect frame = CGRectMake(0, 0, srceenSize.width, srceenSize.width);
  
  CustomGLView *glView = [[CustomGLView alloc] initWithFrame:frame];
  glView.center = self.view.center;
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


/*
 着色器程序对象(Shader Program Object)是多个着色器合并之后并最终链接完成的版本。如果要使用刚才编译的着色器我们必须把它们链接(Link)为一个着色器程序对象，然后在渲染对象的时候激活这个着色器程序。已激活着色器程序的着色器将在我们发送渲染调用的时候被使用。
 
 当链接着色器至一个程序的时候，它会把每个着色器的输出链接到下个着色器的输入。当输出和输入不匹配的时候，你会得到一个连接错误。
 
 */

@end
