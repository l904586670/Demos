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

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if (!_hideGLConfig) {
    self.delegate = self;
    self.preferredFramesPerSecond = 60;
    self.content = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.content];
    
    GLKView *glkView = [[GLKView alloc] initWithFrame:[self contentRect] context:self.content];
    self.glkView = glkView;
    [self.view addSubview:glkView];
    glkView.delegate = self;
    //  (GLKView *)self.view;
    //  glkView.context = self.content;
    //  glkView.delegate = self;
    glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;  //颜色缓冲区格式
  }
}

- (CGRect)contentRect {
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  return CGRectMake(0, posY, screenSize.width, screenSize.height - posY);
}

#pragma mark - Common Methods

- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
  GLuint verShader, fragShader;
  GLint program = glCreateProgram();
  
  //编译
  [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
  [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
  
  glAttachShader(program, verShader);
  glAttachShader(program, fragShader);
  
  //释放不需要的shader
  glDeleteShader(verShader);
  glDeleteShader(fragShader);
  
  return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
  //读取字符串
  NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
  const GLchar* source = (GLchar *)[content UTF8String];
  
  *shader = glCreateShader(type);
  glShaderSource(*shader, 1, &source, NULL);
  glCompileShader(*shader);
}

@end
