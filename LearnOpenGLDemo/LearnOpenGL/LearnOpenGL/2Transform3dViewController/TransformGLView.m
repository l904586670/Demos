//
//  TransformGLView.m
//  LearnOpenGL
//
//  Created by User on 2019/7/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "TransformGLView.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/gl.h>
#import "GLESUtils.h"
#import "GLESMath.h"

@interface TransformGLView ()

@property (nonatomic, strong) CAEAGLLayer *eagLayer;
@property (nonatomic, strong) EAGLContext *content;

@property (nonatomic, assign) GLuint shaderProgram;
@property (nonatomic, assign) GLuint    VBO;

@property (nonatomic , assign) GLuint myColorRenderBuffer;
@property (nonatomic , assign) GLuint myColorFrameBuffer;

@end

@implementation TransformGLView {
  float degree;
  float yDegree;
  BOOL bX;
  BOOL bY;
  NSTimer* myTimer;
}


+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupLayer];
    
    [self setupContent];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self render];
    
    [self drawButtons];
  }
  return self;
}


- (void)onTimer {
  if (!myTimer) {
    myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(onRes) userInfo:nil repeats:YES];
  }
  bX = !bX;
}


- (void)onYTimer {
  if (!myTimer) {
    myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(onRes) userInfo:nil repeats:YES];
  }
  bY = !bY;
}


- (void)onRes {
  degree += bX * 5;
  yDegree += bY * 5;
  [self render];
}

#pragma mark - setup

- (void)setupLayer {
  self.eagLayer = (CAEAGLLayer *)self.layer;
  
  // 设置放大倍数
  [self setContentScaleFactor:[UIScreen mainScreen].scale];
  
  // CALayer 默认是透明的，必须将它设为不透明才能让其可见
  self.eagLayer.opaque = YES;
  
  // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
  self.eagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContent {
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
  if (!context) {
    NSLog(@"Failed to initialize OpenGLES 3.0 context");
    exit(1);
  }
  
  // 设置为当前上下文
  if (![EAGLContext setCurrentContext:context]) {
    NSLog(@"Failed to set current OpenGL context");
    exit(1);
  }
  self.content = context;
}

- (void)destoryRenderAndFrameBuffer {
  glDeleteFramebuffers(1, &_myColorFrameBuffer);
  self.myColorFrameBuffer = 0;
  glDeleteRenderbuffers(1, &_myColorRenderBuffer);
  self.myColorRenderBuffer = 0;
}

- (void)setupRenderBuffer {
  GLuint buffer;
  glGenRenderbuffers(1, &buffer);
  self.myColorRenderBuffer = buffer;
  glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
  // 为 颜色缓冲区 分配存储空间
  [self.content renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eagLayer];
}

- (void)setupFrameBuffer {
  GLuint buffer;
  glGenFramebuffers(1, &buffer);
  self.myColorFrameBuffer = buffer;
  // 设置为当前 framebuffer
  glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
  // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                            GL_RENDERBUFFER, self.myColorRenderBuffer);
}


- (void)render {
  glClearColor(0.85, 0.85, 0.85, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
  CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
  glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
  
  if (self.shaderProgram) {
    glDeleteProgram(self.shaderProgram);
    self.shaderProgram = 0;
  }
  
  NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"transformShaderv" ofType:@"glsl"];
  NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"transformShaderf" ofType:@"glsl"];
  self.shaderProgram = [self loadShaders:vertFile frag:fragFile];
  
  //链接
  glLinkProgram(self.shaderProgram);
  GLint linkSuccess;
  glGetProgramiv(self.shaderProgram, GL_LINK_STATUS, &linkSuccess);
  if (linkSuccess == GL_FALSE) { //连接错误
    GLchar messages[256];
    glGetProgramInfoLog(self.shaderProgram, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"error%@", messageString);
    return ;
  } else {
    glUseProgram(self.shaderProgram); //成功便使用，避免由于未使用导致的的bug
  }

  // 前三个是顶点坐标， 后面两个是纹理坐标
  GLfloat vertexData[] = {
    -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上
    0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上
    -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下
    0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下
    0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点
  };
  
  GLuint indices[] = {
    0, 3, 2,
    0, 1, 3,
    0, 2, 4,
    0, 4, 1,
    2, 3, 4,
    1, 4, 3,
  };
  
  if (self.VBO == 0) {
    glGenBuffers(1, &_VBO);
  }
  
  glBindBuffer(GL_ARRAY_BUFFER, _VBO);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_DYNAMIC_DRAW);
  glBindBuffer(GL_ARRAY_BUFFER, _VBO);


  GLuint position = glGetAttribLocation(self.shaderProgram, "position");
  glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
  glEnableVertexAttribArray(position);
  
  GLuint positionColor = glGetAttribLocation(self.shaderProgram, "positionColor");
  glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, (float *)NULL + 3);
  glEnableVertexAttribArray(positionColor);
  
  GLuint projectionMatrixSlot = glGetUniformLocation(self.shaderProgram, "projectionMatrix");
  GLuint modelViewMatrixSlot = glGetUniformLocation(self.shaderProgram, "modelViewMatrix");
  
  float width = self.frame.size.width;
  float height = self.frame.size.height;
  
  KSMatrix4 _projectionMatrix;
  ksMatrixLoadIdentity(&_projectionMatrix);
  float aspect = width / height; //长宽比
  
  ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f); //透视变换，视角30°
  
  //设置glsl里面的投影矩阵
  glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
  
  glEnable(GL_CULL_FACE);
  
  
  KSMatrix4 _modelViewMatrix;
  ksMatrixLoadIdentity(&_modelViewMatrix);
  //平移
  ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
  
  KSMatrix4 _rotationMatrix;
  ksMatrixLoadIdentity(&_rotationMatrix);
  //旋转
  ksRotate(&_rotationMatrix, degree, 1.0, 0.0, 0.0); //绕X轴
  ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0); //绕Y轴
  
  //把变换矩阵相乘，注意先后顺序
  ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
  //    ksMatrixMultiply(&_modelViewMatrix, &_modelViewMatrix, &_rotationMatrix);
  
  // Load the model-view matrix
  glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
  
  glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
  
  [self.content presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)drawButtons {
  UIButton *xBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  xBtn.frame = CGRectMake(0, 10, 100, 30);
  [xBtn setTitle:@"X" forState:UIControlStateNormal];
  [xBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [self addSubview:xBtn];
  [xBtn addTarget:self action:@selector(onTimer) forControlEvents:UIControlEventTouchUpInside];
  
  UIButton *yBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  yBtn.frame = CGRectMake(110, 10, 100, 30);
  [yBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [yBtn setTitle:@"Y" forState:UIControlStateNormal];
  [self addSubview:yBtn];
  [yBtn addTarget:self action:@selector(onYTimer) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Private Methods

- (GLuint)setupTexture:(NSString *)fileName {
  // 1获取图片的CGImageRef
  UIImage *img = [UIImage imageNamed:fileName];
  CGImageRef spriteImage = img.CGImage;
  if (!spriteImage) {
    NSLog(@"Failed to load image %@", fileName);
    exit(1);
  }
  
  // 2 读取图片的大小
  size_t width = CGImageGetWidth(spriteImage);
  size_t height = CGImageGetHeight(spriteImage);
  size_t bitsPerComponent = CGImageGetBitsPerComponent(spriteImage); // 一般==8, 8位
  size_t bytesPerRow = CGImageGetBytesPerRow(spriteImage); // 一行占多少个字节,一般 == width * 4
  
  GLubyte *spriteData = (GLubyte *)calloc(bytesPerRow * height, sizeof(GLubyte)); //rgba共4个byte
  
  CGContextRef spriteContext = CGBitmapContextCreate(spriteData,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     CGImageGetColorSpace(spriteImage),
                                                     kCGImageAlphaPremultipliedLast);
  
  // 3在CGContextRef上绘图
  CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
  CGContextRelease(spriteContext);
  
  // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
  glBindTexture(GL_TEXTURE_2D, 0);
  
  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  
  float fw = width, fh = height;
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
  
  glBindTexture(GL_TEXTURE_2D, 0);
  
  free(spriteData);
  return 0;
}

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
