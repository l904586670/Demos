//
//  GLBaseViewController.m
//  LearnOpenGL
//
//  Created by User on 2019/7/6.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "GLBaseViewController.h"

@interface GLBaseViewController ()

@end

@implementation GLBaseViewController

- (instancetype)init {
  self = [super init];
  if (self) {
    
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.delegate = self;
  self.preferredFramesPerSecond = 60;
  self.content = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
  [EAGLContext setCurrentContext:self.content];
  
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGRect frame = CGRectMake(0, posY, screenSize.width, screenSize.height - posY);
  
  GLKView *glkView = [[GLKView alloc] initWithFrame:frame context:self.content];
  self.glkView = glkView;
  [self.view addSubview:glkView];
  glkView.delegate = self;
//  (GLKView *)self.view;
//  glkView.context = self.content;
  //  glkView.delegate = self;
  glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;  //颜色缓冲区格式
}

@end
