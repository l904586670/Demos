//
//  PaintMetalView.m
//  PaintByMetalDemo
//
//  Created by User on 2019/8/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "PaintMetalView.h"

#import "DHMetalHelper.h"
#import "CommonDefinition.h"

/**
 先绘制到一个纹理上面 (paintTexture). 然后在把纹理上的内容绘制drawable.texture上
 */

static const NSUInteger kMaxInflightBuffers = 3;

@interface PaintMetalView ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

// 涂抹的渲染管道
@property (nonatomic, strong) id <MTLRenderPipelineState> brushPipelineState;
// 渲染的渲染管道
@property (nonatomic, strong) id <MTLRenderPipelineState> paintPipelineState;

@property (nonatomic, strong) id<MTLTexture> brushTexture;
@property (nonatomic, strong) id<MTLTexture> paintTexture;
@property (nonatomic, strong) id<MTLBuffer> baseVertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> baseIndicesBuffer;

@property (nonatomic, assign) BOOL firstTouch;
@property (nonatomic, assign) CGPoint location;
@property (nonatomic, assign) CGPoint previousLocation;
@property (nonatomic, strong) dispatch_semaphore_t frameBoundarySemaphore;

@property (nonatomic, assign) simd_float4 paintColor;

@end

@implementation PaintMetalView

+ (Class)layerClass {
  return [CAMetalLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];
    _brushSize = 30.0;
    _brushColor = [UIColor redColor];
    
    [self configureMetal];
  }
  return self;
}

#pragma mark - Metal

- (void)configureMetal {
  self.device = MTLCreateSystemDefaultDevice();
  if (!self.device) {
    NSAssert(NO, @"device don't support metal");
  }
  self.device = self.device;
  
  self.commandQueue = [self.device newCommandQueue];
  
  CAMetalLayer *layer = (CAMetalLayer *)self.layer;
  
  layer.framebufferOnly = YES;
  layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  layer.contentsScale = [UIScreen mainScreen].scale;
  layer.device = self.device;
  layer.opaque = NO;
  
  _frameBoundarySemaphore = dispatch_semaphore_create(kMaxInflightBuffers);
  
  [self setupPipeline];
  
  [self loadTextureData];
}

- (void)setupPipeline {
  self.brushPipelineState = [DHMetalHelper renderPipelineStateWithDevice:_device vertexName:@"vertexPaintShader" fragmentName:@"fragmentPaintShader" blendEnabled:YES];
  
  self.paintPipelineState = [DHMetalHelper renderPipelineStateWithDevice:_device vertexName:@"basic_vertex" fragmentName:@"basic_fragment" blendEnabled:NO];
}

- (void)loadTextureData {
  UIImage *brushImage = [UIImage imageNamed:@"Particle.png"];
  if (!brushImage) {
    NSAssert(NO, @"Not find Particle.png");
    return;
  }
  
  _brushTexture = [DHMetalHelper textureWithImage:brushImage device:_device];
  
  size_t width = CGRectGetWidth(self.frame) * [UIScreen mainScreen].scale;
  size_t height = CGRectGetHeight(self.frame) * [UIScreen mainScreen].scale;
  _paintTexture = [DHMetalHelper emptyTextureWithWidth:width height:height device:_device];
  
  typedef struct { //坐标加纹理坐标
    GLfloat x;     //position
    GLfloat y;
    GLfloat uvX;   //texCoord
    GLfloat uvY;
  } YiquxMTLVertex;
  
  static const YiquxMTLVertex kBaseVertices[4] = {
    {-1, 1, 0, 0},
    {1, 1, 1, 0},
    {-1, -1, 0, 1},
    {1, -1, 1, 1}
  };
  _baseVertexBuffer = [_device newBufferWithBytes:kBaseVertices length:sizeof(kBaseVertices) options:MTLResourceCPUCacheModeDefaultCache];
  static const uint16_t kBaseIndices[6] = {0, 1, 2, 2, 3, 1};
  _baseIndicesBuffer = [_device newBufferWithBytes:kBaseIndices length:sizeof(kBaseIndices) options:MTLResourceCPUCacheModeDefaultCache];
}

#pragma mark - Base Methods

// Drawings a line onscreen based on where the user touches
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end {
  dispatch_semaphore_wait(_frameBoundarySemaphore, DISPATCH_TIME_FOREVER);
  __weak typeof(self) weakSelf = self;
  [self.commandQueue.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuffer) {
    dispatch_semaphore_signal(weakSelf.frameBoundarySemaphore);
  }];
  
  static Vertex_t *vertextData = NULL;
  static NSUInteger vertexMax = 64;
  NSUInteger vertexCount = 0;
  
  //   Allocate vertex array buffer
  if (vertextData == NULL) {
    vertextData = malloc(vertexMax * sizeof(Vertex_t));
  }
  
  NSUInteger count = 1;
  
  // Add points to the buffer so there are drawing points every X pixels
  count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / (self.brushSize/3.0)), 1);
  
  for (int32_t i = 0; i < count; ++i) {
    if( vertexCount == vertexMax ) {
      vertexMax = 2 * vertexMax;
      vertextData = realloc(vertextData, vertexMax * sizeof(Vertex_t));
    }
    
    //        屏幕坐标 转换到 [-1.0, 1.0];
    float posX = (start.x + (end.x - start.x) * ((float)(i + 1) / (float)count)) *2.0  / CGRectGetWidth(self.bounds) - 1.0;
    float posY = 1.0 -  (start.y + (end.y - start.y) * ((float)(i + 1) / (float)count)) *2.0 / CGRectGetHeight(self.bounds);
    if (posX > 1.0) {
      posX = 1.0;
    }
    if (posX < -1.0) {
      posX = -1.0;
    }
    if (posY > 1.0) {
      posY = 1.0;
    }
    if (posY < -1.0) {
      posY = -1.0;
    }
    
    vertextData[i] = (Vertex_t){posX, posY};
    //    NSLog(@"x : %g, y : %g", posX, posY);
    vertexCount += 1;
  }
  
  
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  
  /*
   Encoder
   // 块命令 copy texture buffer 资源
   1. id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
   // 渲染命令，用于绘图
   2. id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
   // 并行渲染命令
   3. id<MTLParallelRenderCommandEncoder> parallelEncoder = [commandBuffer parallelRenderCommandEncoderWithDescriptor:renderPassDescriptor];
   // 处理高并发数据
   4. id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
   */
  CAMetalLayer *layer = (CAMetalLayer *)self.layer;
  id<CAMetalDrawable> drawable = [layer nextDrawable];
  
  MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
  renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
  renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
  renderPassDescriptor.colorAttachments[0].texture = _paintTexture;
  
  id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder
  if (!renderEncoder) {
    NSLog(@"renderEncoder fail");
    return;
  }
  
  [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _paintTexture.width, _paintTexture.height, -1.0, 1.0}]; // 设置显示区域
  
  [renderEncoder setRenderPipelineState:self.brushPipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用
  
  // 设置顶点信息
  [renderEncoder setVertexBytes:vertextData length:sizeof(Vertex_t) * vertexCount atIndex:0];
  
  // 传入brushSize尺寸信息
  float brushW = _brushSize * [UIScreen mainScreen].scale;
  [renderEncoder setVertexBytes:&brushW length:sizeof(float) atIndex:1];
  
  // 传入纹理信息
  [renderEncoder setFragmentTexture:self.brushTexture atIndex:0];
  
  const CGFloat *components = CGColorGetComponents(_brushColor.CGColor);
  simd_float4 paintColor = {components[0], components[1], components[2], components[3]};
  [renderEncoder setFragmentBytes:&paintColor length:sizeof(simd_float4) atIndex:0];
  
  [renderEncoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:0 vertexCount:vertexCount];
  [renderEncoder endEncoding]; // 结束
  
  // 把纹理绘制出来
  MTLRenderPassDescriptor *paintPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  
  paintPassDescriptor.colorAttachments[0].texture = drawable.texture;
  paintPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
  paintPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
  paintPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
  
  id<MTLRenderCommandEncoder> paintRenderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:paintPassDescriptor];
  if (!paintRenderEncoder) {
    return;
  }
  
  [paintRenderEncoder setViewport:(MTLViewport){0.0, 0.0, drawable.texture.width, drawable.texture.height}];
  [paintRenderEncoder setRenderPipelineState:_paintPipelineState];
  [paintRenderEncoder setVertexBuffer:_baseVertexBuffer offset:0 atIndex:0];
  [paintRenderEncoder setFragmentTexture:_paintTexture atIndex:0];
  float alpha = 1.0;
  [paintRenderEncoder setFragmentBytes:&alpha length:sizeof(float) atIndex:0];
  
  [paintRenderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:6 indexType:MTLIndexTypeUInt16 indexBuffer:_baseIndicesBuffer indexBufferOffset:0];
  
  [paintRenderEncoder endEncoding];

  //Committing a CommandBuffer
  [commandBuffer presentDrawable:drawable]; // 显示
  [commandBuffer commit];
}

#pragma mark - OverWirte Methods

- (BOOL)canBecomeFirstResponder {
  return YES;
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  
  _firstTouch = YES;
  // Convert touch point from UIView referential to OpenGL one (upside-down flip)
  _location = [[touches anyObject] locationInView:self];
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  
  UITouch *touch = [touches anyObject];
  // Convert touch point from UIView referential to OpenGL one (upside-down flip)
  if (_firstTouch) {
    _firstTouch = NO;
    _previousLocation = [touch previousLocationInView:self];
    
  } else {
    _location = [touch locationInView:self];
    _previousLocation = [touch previousLocationInView:self];
  }
  
  // Render the stroke
  [self renderLineFromPoint:_previousLocation toPoint:_location];
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  if (_firstTouch) {
    _firstTouch = NO;
    _previousLocation = [touch previousLocationInView:self];
    [self renderLineFromPoint:_previousLocation toPoint:_location];
  }
}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

@end
