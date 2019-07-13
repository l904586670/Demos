//
//  DrawTriangleViewController.m
//  LearnOpenGL
//
//  Created by User on 2019/7/6.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "DrawTriangleViewController.h"

#import "TriangleGLView.h"

@interface DrawTriangleViewController () <GLKViewControllerDelegate>

@property (nonatomic, strong) GLKBaseEffect *effect;

@property (nonatomic, assign) GLuint vao;

@property (nonatomic, assign) GLuint textureVAO;
@property (nonatomic, assign) GLuint textureEBO;
@property (nonatomic, assign) GLbyte indexCount;

@property (nonatomic, assign) BOOL imgShowState;

@end

@implementation DrawTriangleViewController

- (void)viewDidLoad {
//  [super viewDidLoad];
  
  self.hideGLConfig = YES;
  
  TriangleGLView *triangleView = [[TriangleGLView alloc] initWithFrame:self.contentRect];
  [self.view addSubview:triangleView];
  [triangleView renderTriangle];
  
//  [self setupUI];
//
//  [self uploadVertexArray];
//
//  [self uploadPhotoVertexArray];
//
//  [self loadTexture];
}

- (void)dealloc {
  [self tearDownGL];
}

- (void)uploadVertexArray {
  self.effect = [[GLKBaseEffect alloc] init];
  
  // 三角形顶点坐标(x, y, z) 顶点颜色(r, g, b, a), 纹理
  GLfloat vertexData[] = {
    0.0, 0.0, 0.0,   1.0, 0.0, 0.0, 1,
    0.0, -0.6, 0.0,  0.0, 1.0, 0.0, 1,
    0.6, 0.0, 0.0,   0.0, 0.0, 1.0, 1,
    
    0.0, 0.0, 0.0,   1.0, 0.0, 0.0, 1,
    0.0, 0.6, 0.0,   0.0, 1.0, 0.0, 1,
    -0.6, 0.0, 0.0,   0.0, 0.0, 1.0, 1,
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
  
  // 释放
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
}


- (void)uploadPhotoVertexArray {
  self.effect = [[GLKBaseEffect alloc] init];
  
  // 顶点坐标[-1, 1] 纹理 坐标 [0, 1]
  // 三角形顶点坐标(x, y, z)  纹理坐标(x,y)
  GLfloat vertexData[] = {
    1.0, 1.0, 0.0,   1.0, 1.0,    // 右上
    1.0, -1.0, 0.0,  1.0, 0.0,    // 右下
    -1.0, -1.0, 0.0, 0.0, 0.0,    // 左下
    -1.0, 1.0, 0.0f, 0.0f, 1.0f,  // 左上
  };
  
  GLbyte indices[] = {
    0, 1, 2,
    2, 3, 0
  };
  
  glGenVertexArrays(1, &_textureVAO);
  glBindVertexArray(_textureVAO);
  
  unsigned int vbo;
  glGenBuffers(1, &vbo);
  glBindBuffer(GL_ARRAY_BUFFER, vbo);

  glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
  
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  // , 字符长度, 类型, ,步长, 偏移量
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), nil);
  
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (GLfloat *)(sizeof(GLfloat) * 3));
  
  // EBO
  // Generatea a buffer for our element buffer object.
  glGenBuffers(1, &_textureEBO);
  // Bind the element buffer object we just generated (created).
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _textureEBO);
  // Pass data for our element indices to the element buffer object.
  NSInteger size = sizeof(indices) / sizeof(GLbyte);
  _indexCount = size;
  
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, _indexCount, indices, GL_STATIC_DRAW);
  
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
}

#pragma mark - UI

- (void)setupUI {
  UISwitch *swt = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
  [swt addTarget:self action:@selector(onSwicth:) forControlEvents:UIControlEventValueChanged];
  UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:swt];
  self.navigationItem.rightBarButtonItem = barBtn;
  _imgShowState = NO;
}

- (void)onSwicth:(UISwitch *)sender {
  _imgShowState = !_imgShowState;
  
  [self glkView:self.glkView drawInRect:self.glkView.frame];
}

#pragma mark - Private Methods

- (void)tearDownGL {
  [EAGLContext setCurrentContext:self.content];
  
  // Delete the vertex array object, the element buffer object, and the vertex buffer object.
  glDeleteBuffers(1, &_vao);
  
  glDeleteBuffers(1, &_textureVAO);
  glDeleteBuffers(1, &_textureEBO);

  // Set the current EAGLContext to nil.
  [EAGLContext setCurrentContext:nil];
  self.content = nil;
}

- (void)loadTexture {
  //纹理贴图
  NSString* filePath = [[NSBundle mainBundle] pathForResource:@"img1" ofType:@"jpg"];
  NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];//GLKTextureLoaderOriginBottomLeft 纹理坐标系是相反的
  GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
  
  self.effect.texture2d0.enabled = GL_TRUE;
  self.effect.texture2d0.name = textureInfo.name;
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  // 1
  glClearColor(0.85, 0.85, 0.85, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
  
  [self.effect prepareToDraw];
  if (_imgShowState) {
    glBindVertexArray(_textureVAO);
    glDrawElements(GL_TRIANGLES, _indexCount, GL_UNSIGNED_BYTE, NULL);
    glBindVertexArray(0);
  } else {
    glBindVertexArray(_vao);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glBindVertexArray(0);
  }
}

#pragma mark - GLKViewControllerDelegate

- (void)glkViewControllerUpdate:(GLKViewController *)controller {
  
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause {
  
}

/**
 // 创建顶点缓冲对象 VBO
 
 会在GPU内存（通常被称为显存）中储存大量顶点。使用这些缓冲对象的好处是我们可以一次性的发送一大批数据到显卡上，而不是每个顶点发送一次。从CPU把数据发送到显卡相对较慢，所以只要可能我们都要尝试尽量一次性发送尽可能多的数据。当数据发送至显卡的内存中后，顶点着色器几乎能立即访问顶点，这是个非常快的过程
 GLuint buffer;
 glGenBuffers(1, &buffer);
 //  OpenGL有很多缓冲对象类型，顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER。OpenGL允许我们同时绑定多个缓冲，只要它们是不同的缓冲类型。我们可以使用glBindBuffer函数把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上：
 glBindBuffer(GL_ARRAY_BUFFER, buffer);
 
 // 从这一刻起，我们使用的任何（在GL_ARRAY_BUFFER目标上的）缓冲调用都会用来配置当前绑定的缓冲(VBO)。然后我们可以调用glBufferData函数，它会把之前定义的顶点数据复制到缓冲的内存中：
 它的第一个参数是目标缓冲的类型：顶点缓冲对象当前绑定到GL_ARRAY_BUFFER目标上。第二个参数指定传输数据的大小(以字节为单位)；用一个简单的sizeof计算出顶点数据大小就行。第三个参数是我们希望发送的实际数据。
 
 第四个参数指定了我们希望显卡如何管理给定的数据。它有三种形式：
 
 GL_STATIC_DRAW ：数据不会或几乎不会改变。
 GL_DYNAMIC_DRAW：数据会被改变很多。
 GL_STREAM_DRAW ：数据每次绘制时都会改变。
 glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
 
 */

@end
