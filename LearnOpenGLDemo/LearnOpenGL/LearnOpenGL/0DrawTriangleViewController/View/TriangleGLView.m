//
//  TriangleGLView.m
//  LearnOpenGL
//
//  Created by User on 2019/7/13.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "TriangleGLView.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/gl.h>

#import "GLESUtils.h"


@interface TriangleGLView ()

@property (nonatomic, strong) CAEAGLLayer *eaGlLayer;
@property (nonatomic, strong) EAGLContext *content;

@property (nonatomic, assign) BOOL initialized;


// https://learnopengl-cn.readthedocs.io/zh/latest/04%20Advanced%20OpenGL/05%20Framebuffers/
@property (nonatomic, assign) GLuint viewFrameBuffer;   // fbo
@property (nonatomic, assign) GLuint colorRenderBuffer;
// OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist)
@property (nonatomic, assign) GLuint depthRenderbuffer;

// The pixel dimensions of the backbuffer
@property (nonatomic, assign) GLint backingWidth;
@property (nonatomic, assign) GLint backingHeight;

@property (nonatomic, assign) GLuint shaderProgram;

@end

@implementation TriangleGLView

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    
    [self setupLayer];
    
    [self setupContent];
  }
  return self;
}

- (void)layoutSubviews {
  [EAGLContext setCurrentContext:self.content];
  
  if (!_initialized) {
    _initialized = [self initGLConfig];
  } else {
    [self resizeFromLayer:(CAEAGLLayer*)self.eaGlLayer];
  }
  
}

#pragma mark - Init

- (void)setupLayer {
  self.eaGlLayer = (CAEAGLLayer *)self.layer;
  
  // 设置放大倍数
  [self setContentScaleFactor:[UIScreen mainScreen].scale];
  
  // CALayer 默认是透明的，必须将它设为不透明才能让其可见
  self.eaGlLayer.opaque = YES;
  
  // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
  self.eaGlLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContent {
  self.content = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
  if (!_content || ![EAGLContext setCurrentContext:_content]) {
    NSAssert(NO, @"initialize EAGLContent GLES3.0 Fail");
    return;
  }
}

- (BOOL)initGLConfig {
  // Generate IDs for a framebuffer object and a color renderbuffer
  glGenFramebuffers(1, &_viewFrameBuffer);
  glBindBuffer(GL_FRAMEBUFFER, _viewFrameBuffer);
  
  glGenRenderbuffers(1, &_colorRenderBuffer);
  glBindBuffer(GL_RENDERBUFFER, _colorRenderBuffer);
  
  // This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
  // allowing us to draw into a buffer that will later be rendered to screen wherever the layer is (which corresponds with our view).
  // 为 颜色缓冲区 分配存储空间
  [_content renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaGlLayer];
  
  glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                            GL_COLOR_ATTACHMENT0,
                            GL_RENDERBUFFER,
                            _colorRenderBuffer);
  
  
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
  
  
  // For this sample, we do not need a depth buffer. If you do, this is how you can create one and attach it to the framebuffer:
  //    glGenRenderbuffers(1, &depthRenderbuffer);
  //    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
  //    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
  //    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
  
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
  {
    NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    return NO;
  }
  
  // Setup the view port in Pixels
  glViewport(0, 0, _backingWidth, _backingHeight);
  
  
  return YES;
}


- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
  // Allocate color buffer backing based on the current layer size
  glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
  [_content renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
  
  // For this sample, we do not need a depth buffer. If you do, this is how you can allocate depth buffer backing:
  //    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
  //    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
  //    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
  
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
  {
    NSLog(@"Failed to make complete framebuffer objectz %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    return NO;
  }
  
  /*
  // Update projection matrix
  GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, _backingWidth, 0, _backingHeight, -1, 1);
  GLKMatrix4 modelViewMatrix = GLKMatrix4Identity; // this sample uses a constant identity modelView matrix
  GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
  
  glUseProgram(program[PROGRAM_POINT].id);
  glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
  */
  
  // Update viewport
  glViewport(0, 0, _backingWidth, _backingHeight);
  
  return YES;
}


- (void)renderTriangle {
  glClearColor(0.85, 0.85, 0.85, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
  
  GLfloat vertices[] = {
    -0.5f, -0.5f, 0.0f,
    0.5f, -0.5f, 0.0f,
    0.0f,  0.5f, 0.0f
  };
  
  NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"simpleShaderV" ofType:@"vsh"];
  NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"simpleShaderF" ofType:@"fsh"];
  self.shaderProgram = [self loadShaders:vertFile frag:fragFile];
  
  
  glUseProgram(_shaderProgram);
  
  GLuint VBO;
  glGenBuffers(1, &VBO);
  
  glBindBuffer(GL_ARRAY_BUFFER, VBO);
  
  // 把之前定义的顶点数据复制到缓冲的内存中：
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
  
  
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), nil);
  
//  GLuint position = glGetAttribLocation(self.shaderProgram, "position");
//  glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
//  glEnableVertexAttribArray(position);
//  
//  GLuint textCoor = glGetAttribLocation(self.shaderProgram, "textCoordinate");
//  glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
//  glEnableVertexAttribArray(textCoor);

  
  glDrawArrays(GL_TRIANGLES, 0, 3);
  [self.content presentRenderbuffer:GL_RENDERBUFFER];
 
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
