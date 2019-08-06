//
//  BaseMetalView.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "BaseMetalView.h"

#import "CommonDefinition.h"
#import <GLKit/GLKit.h>
#import "DHMetalHelper.h"

@interface BaseMetalView () <MTKViewDelegate>

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;
@property (nonatomic, assign) NSInteger     indexNumber;
@property (nonatomic, strong) id<MTLTexture> texture;

@property (nonatomic, assign) CGFloat rorateX;
@property (nonatomic, assign) CGFloat rorateY;
@property (nonatomic, assign) CGFloat rorateZ;

@end

@implementation BaseMetalView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self initiatizeMatel];
    
    [self setupPipeline];
    
    [self loadModelData];
  }
  return self;
}

#pragma mark - Setup Metal Config

- (void)initiatizeMatel {
  // get the Dvice
  _device = MTLCreateSystemDefaultDevice();
  if (!_device) {
    NSAssert(NO, @"current device GPU not support Metal");
  } else {
    NSLog(@"current GPU name : %@", _device.name);
  }
  
  // Create a CommandQueue
  _commandQueue = [_device newCommandQueue];
  
  _mtkView = [[MTKView alloc] initWithFrame:self.bounds device:_device];
  _mtkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _mtkView.clearColor = MTLClearColorMake(1, 1, 1, 1.0);
  _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
  _mtkView.delegate = self;
  [self addSubview:_mtkView];
  
  _viewportSize = (vector_uint2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
}


- (void)loadModelData {
  static const LBVertex vertexData[] = {
    {{-0.5f, 0.5f, 0.0f, 1.0f},  {0.0f, 0.0f, 0.5f, 1.f},  {0.0f, 1.0f}},//左上
    {{0.5f, 0.5f, 0.0f, 1.0f},   {0.0f, 0.5f, 0.0f, 1.f},  {1.0f, 1.0f}},//右上
    {{-0.5f, -0.5f, 0.0f, 1.0f}, {0.5f, 0.0f, 1.0f, 1.f},  {0.0f, 0.0f}},//左下
    {{0.5f, -0.5f, 0.0f, 1.0f},  {0.0f, 0.0f, 0.5f, 1.f},  {1.0f, 0.0f}},//右下
    {{0.0f, 0.0f, 1.0f, 1.0f},   {1.0f, 1.0f, 1.0f, 1.f},  {0.5f, 0.5f}},//顶点
  };
  
  self.vertexBuffer = [_device newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceStorageModeShared];
  
  static int indices[] =
  { // 索引
    0, 3, 2,
    0, 1, 3,
    0, 2, 4,
    0, 4, 1,
    2, 3, 4,
    1, 4, 3,
  };
  self.indexBuffer = [_device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceStorageModeShared];
  
  self.indexNumber = sizeof(indices) / sizeof(int);
  
  UIImage *image = [UIImage imageNamed:@"img1.jpg"];
  // 创建纹理描述符
  self.texture = [DHMetalHelper textureWithImage:image device:_device];
}

- (void)setupPipeline {
  NSError *error = nil;
//  NSString * libraryFile = [[NSBundle mainBundle] pathForResource:@"CommonShader" ofType:@"metallib"];
//  id <MTLLibrary> defaultLibrary = [_device newLibraryWithFile:libraryFile error:&error];
  id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
  if (error) {
    NSAssert(NO, @"creat library error [CommonShader.metal]");
  }
  id <MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"vertexShaderMain"];
  id <MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"fragmentShaderMain"];
  
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  
  // 描述顶点和颜色位置和偏移量
  MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
  vertexDescriptor.attributes[0].offset = 0;
  vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4; // position
  vertexDescriptor.attributes[0].bufferIndex = 0;
  
  vertexDescriptor.attributes[1].offset = sizeof(float) * 4; // 16
  vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4; // texCoords
  vertexDescriptor.attributes[1].bufferIndex = 0;
  
  vertexDescriptor.attributes[2].offset = sizeof(float) * 8;
  vertexDescriptor.attributes[2].format = MTLVertexFormatFloat2; // texCoords
  vertexDescriptor.attributes[2].bufferIndex = 0;
  
  vertexDescriptor.layouts[0].stepRate = 1;
  vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
  vertexDescriptor.layouts[0].stride = sizeof(LBVertex);
  
  pipelineStateDescriptor.vertexDescriptor = vertexDescriptor;
  
  // 顶点描述
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
  pipelineStateDescriptor.vertexFunction = vertexFunc;
  pipelineStateDescriptor.fragmentFunction = fragmentFunc;
  
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
  if (error) {
    NSAssert(NO, @"creat pipelineState Error : %@", error.description);
  }
}

- (void)render {
  // Get a command buffer 每次渲染都要单独创建一个CommandBuffer
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  
  // Start a Render Pass
  MTLRenderPassDescriptor *renderPassDescriptor = [_mtkView currentRenderPassDescriptor];
  /*
   MTLRenderPassDescriptor
   Color Attachment 0
   Color Attachment 1
   Color Attachment 2
   Color Attachment 3
   Depth Attachment
   Stencil Attachment
   */
  if(renderPassDescriptor) {
    
    renderPassDescriptor.colorAttachments[0].texture = self.mtkView.currentDrawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1.0f); // 设置渲染的背景颜色
    
    // Draw
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }]; // 设置显示区域
    [renderEncoder setRenderPipelineState:_pipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用
    
    [renderEncoder setVertexBuffer:self.vertexBuffer
                            offset:0
                           atIndex:0];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setCullMode:MTLCullModeBack];
    
    // 获取矩阵信息
    UniformsMatrix matrix = [self matrix];
    [renderEncoder setVertexBytes:&matrix
                           length:sizeof(matrix)
                          atIndex:1];
    
    [renderEncoder setFragmentTexture:self.texture
                              atIndex:0];
    
    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                              indexCount:self.indexNumber
                               indexType:MTLIndexTypeUInt32
                             indexBuffer:self.indexBuffer
                       indexBufferOffset:0];

    [renderEncoder endEncoding]; // 结束
    
    //Committing a CommandBuffer
    [commandBuffer presentDrawable:_mtkView.currentDrawable]; // 显示
    [commandBuffer commit];
  } else {
    
    // Commit the command buffer
    [commandBuffer commit]; // 提交；
  }
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  _viewportSize = (vector_uint2){size.width, size.height};
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  
  [self render];
}

#pragma mark - Private Methods

- (void)loadImage:(UIImage *)image content:(void(^)(Byte *imgData, size_t bytesPerRow))contentBlock {
  // 1获取图片的CGImageRef
  CGImageRef spriteImage = image.CGImage;
  
  // 2 读取图片的大小
  size_t width = CGImageGetWidth(spriteImage);
  size_t height = CGImageGetHeight(spriteImage);
  
  size_t bitsPerComponent = CGImageGetBitsPerComponent(spriteImage);
  size_t bytesPerRow = CGImageGetBytesPerRow(spriteImage);
  CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(spriteImage);
  
  Byte *spriteData = (Byte *)calloc(width * height * 4, sizeof(Byte)); //rgba共4个byte
  
  CGContextRef spriteContext = CGBitmapContextCreate(spriteData,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     CGImageGetColorSpace(spriteImage),
                                                     bitmapInfo);
  if (!spriteContext) {
    free(spriteData);
    return;
  }
  
  // 3在CGContextRef上绘图
  CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
  CGContextRelease(spriteContext);
  
  if (contentBlock) {
    contentBlock(spriteData, bytesPerRow);
  }
  
  free(spriteData);
  spriteData = NULL;
}

- (UniformsMatrix)matrix {
  CGSize size = self.bounds.size;
  float aspect = fabs(size.width / size.height);
  // 参数:fovyRadians 视角, aspect 视图宽高比 nearZ近视点，farZ远视点
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 10.f);
  
  GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
//  static float x = 0.0, y = 0.0, z = M_PI;
//  x += 0.005;
//  y += 0.005;
//  z += 0.005;
  _rorateX += 0.005;
  _rorateY += 0.010;
  _rorateZ += 0.015;

  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rorateX, 1, 0, 0);
  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rorateY, 0, 1, 0);
  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rorateZ, 0, 0, 1);
  
  UniformsMatrix matrix = {
    [self getMetalMatrixFromGLKMatrix:modelViewMatrix],
    [self getMetalMatrixFromGLKMatrix:GLKMatrix4Identity],
    [self getMetalMatrixFromGLKMatrix:projectionMatrix],
  };
  
  return matrix;
}

- (matrix_float4x4)getMetalMatrixFromGLKMatrix:(GLKMatrix4)matrix {
  matrix_float4x4 ret = (matrix_float4x4){
    simd_make_float4(matrix.m00, matrix.m01, matrix.m02, matrix.m03),
    simd_make_float4(matrix.m10, matrix.m11, matrix.m12, matrix.m13),
    simd_make_float4(matrix.m20, matrix.m21, matrix.m22, matrix.m23),
    simd_make_float4(matrix.m30, matrix.m31, matrix.m32, matrix.m33),
  };
  return ret;
}

@end
