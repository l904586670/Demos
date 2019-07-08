//
//  CustomGLView.m
//  LearnOpenGL
//
//  Created by User on 2019/7/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "CustomGLView.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/gl.h>

@interface CustomGLView ()

@property (nonatomic, strong) CAEAGLLayer *eagLayer;
@property (nonatomic, strong) EAGLContext *content;
@property (nonatomic, assign) GLuint textureVAO;
@property (nonatomic, assign) GLuint shaderProgram;
@property (nonatomic, assign) GLbyte vertexCount;

@property (nonatomic , assign) GLuint myColorRenderBuffer;
@property (nonatomic , assign) GLuint myColorFrameBuffer;

@end

@implementation CustomGLView

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
  }
  return self;
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
  
  
  NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"simpleShaderV" ofType:@"vsh"];
  NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"simpleShaderF" ofType:@"fsh"];
  
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
    1.0,  -1.0, -1.0,       1.0, 0.0,       // 右下,
    -1.0, -1.0, -1.0,       0.0, 0.0,       // 左下
    -1.0, 1.0,  -1.0,       0.0, 1.0,       // 左上
    1.0,  1.0,  -1.0,       1.0, 1.0,       // 右上
  };
  
  GLbyte indices[] = {
    0, 1, 2,
    2, 3, 0
  };
  
  glGenVertexArrays(1, &_textureVAO);
  glBindVertexArray(_textureVAO);

  unsigned int VBO;
  glGenBuffers(1, &VBO);

  glBindBuffer(GL_ARRAY_BUFFER, VBO);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_DYNAMIC_DRAW);

  GLuint position = glGetAttribLocation(self.shaderProgram, "position");
  glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
  glEnableVertexAttribArray(position);
  
  GLuint textCoor = glGetAttribLocation(self.shaderProgram, "textCoordinate");
  glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
  glEnableVertexAttribArray(textCoor);
  
  GLuint textureEBO;
  glGenBuffers(1, &textureEBO);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, textureEBO);
  GLbyte size = sizeof(indices) / sizeof(GLbyte);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, size, indices, GL_STATIC_DRAW);
  
  
  [self setupTexture:@"img1.jpg"];
  
  GLuint rotate = glGetUniformLocation(self.shaderProgram, "rotateMatrix");
  
  
  float radians = 180 * M_PI / 180.0f;
  float s = sin(radians);
  float c = cos(radians);
  
  //z轴旋转矩阵
  GLfloat zRotation[16] = { //
    c, -s, 0, 0, //
    s, c, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1, //
  };
  
  //设置旋转矩阵
  glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
  
//  glDrawArrays(GL_TRIANGLES, 0, 6);
  glDrawElements(GL_TRIANGLES, size, GL_UNSIGNED_BYTE, NULL);
  
  [self.content presentRenderbuffer:GL_RENDERBUFFER];
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
