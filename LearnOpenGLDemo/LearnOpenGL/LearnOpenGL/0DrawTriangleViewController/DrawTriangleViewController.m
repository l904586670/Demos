//
//  DrawTriangleViewController.m
//  LearnOpenGL
//
//  Created by User on 2019/7/6.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "DrawTriangleViewController.h"

@interface DrawTriangleViewController () <GLKViewControllerDelegate>

@property (nonatomic, strong) GLKBaseEffect *effect;

@property (nonatomic, assign) GLuint vao;

@end

@implementation DrawTriangleViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self uploadVertexArray];
  
}

- (void)uploadVertexArray {
  self.effect = [[GLKBaseEffect alloc] init];
  
  // 三角形顶点坐标(x, y, z) 顶点颜色(r, g, b, a)
  GLfloat vertexData[] = {
    0.5, -0.5, 0.0,  1.0, 0.0, 0.0, 1,
    0.5, 0.5, -0.0,  0.0, 1.0, 0.0, 1,
    -0.5, 0.5, 0.0f, 0.0, 0.0, 1.0, 1,
  };
  

  glGenVertexArrays(1, &_vao);
  glBindVertexArray(_vao);
  
  unsigned int vbo;
  glGenBuffers(1, &vbo);
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
  
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), nil);
  
  glEnableVertexAttribArray(GLKVertexAttribColor);
  glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 7 * sizeof(GLfloat), (GLfloat *)(sizeof(GLfloat) * 3));
  
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
}


#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  // 1
  glClearColor(0.85, 0.85, 0.85, 1.0);
  
  // 2
  glClear(GL_COLOR_BUFFER_BIT);
  
  [self.effect prepareToDraw];
  
  glBindVertexArray(_vao);
  glDrawArrays(GL_TRIANGLES, 0, 3);
//  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, NULL);
  glBindVertexArray(0);
}

#pragma mark - GLKViewControllerDelegate

- (void)glkViewControllerUpdate:(GLKViewController *)controller {
  
//  CGFloat aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
//  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 4.0, 10.0);
//  self.effect.transform.projectionMatrix = projectionMatrix;
//  
//  GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0, 0, -6.0);
//  
//  _rotation += (90.0 * self.timeSinceLastUpdate);
//  
//  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 0, 1);
//  self.effect.transform.modelviewMatrix = modelViewMatrix;
  
  //  NSLog(@"-----");
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause {
  
}


@end
