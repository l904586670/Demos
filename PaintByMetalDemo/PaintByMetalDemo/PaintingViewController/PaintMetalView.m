//
//  PaintMetalView.m
//  PaintByMetalDemo
//
//  Created by User on 2019/8/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "PaintMetalView.h"

#import "MetalLoadTextureTool.h"
#import "CommonDefinition.h"

static const NSUInteger kMaxInflightBuffers = 3;

@interface PaintMetalView ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;

@property (nonatomic, strong) id<MTLTexture> brushTexture;
@property (nonatomic, strong) id<MTLTexture> paintTexture;

@property (nonatomic, assign) BOOL firstTouch;
@property (nonatomic, assign) CGPoint location;
@property (nonatomic, assign) CGPoint previousLocation;
@property (nonatomic, strong) dispatch_semaphore_t frameBoundarySemaphore;

@property (nonatomic, assign) float brushSize;  // 笔刷大小, default 30

@property (nonatomic, strong) UIColor *bgColor;

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
  
  [self setupPipelineState];
  
  [self loadTextureData];
}

- (void)setupPipelineState {
  id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
  id <MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"vertexPaintShader"];
  id <MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"fragmentPaintShader"];
  
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  
  pipelineStateDescriptor.vertexFunction = vertexFunc;
  pipelineStateDescriptor.fragmentFunction = fragmentFunc;
  
  pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;      // 不启用深度测试
  pipelineStateDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;    // 不启用stencil
  
  // 像素格式要与CAMetalLayer的像素格式一致
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
  
  // 涂抹的时候需要打开融合. 使纹理的透明度信息和原有内容融合. 否则,涂抹纹理会显示黑色
  // 是否允许颜色融合
  pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
  // 融合方式
  pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
  pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
  pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
  pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
  pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
  pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
  
  //  pipelineStateDescriptor.alphaToCoverageEnabled = YES; // 如果alphaToCoverageEnabled设置为YES，则colorAttachments[0]读取用于输出的alpha通道片段，并用于确定覆盖掩码
  //  pipelineStateDescriptor.alphaToOneEnabled = YES; // alpha通道片段值colorAttachments[0]被强制为1.0
  
  NSError *error = nil;
  _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
  if (error) {
    NSAssert(NO, @"creat pipelineState Error : %@", error.description);
  }
}

- (void)loadTextureData {
  UIImage *brushImage = [UIImage imageNamed:@"Particle.png"];
  if (!brushImage) {
    NSAssert(NO, @"Not find Particle.png");
    return;
  }
  
  _brushTexture = [MetalLoadTextureTool textureWithImage:brushImage device:_device];
  
  size_t width = CGRectGetWidth(self.frame) * [UIScreen mainScreen].scale;
  size_t height = CGRectGetHeight(self.frame) * [UIScreen mainScreen].scale;
  MTLTextureDescriptor *paintDescriptor = [[MTLTextureDescriptor alloc] init];
  paintDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
  paintDescriptor.width = width;
  paintDescriptor.height = height;
  paintDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
  self.paintTexture = [_device newTextureWithDescriptor:paintDescriptor];
}

#pragma mark - Base Methods

// Drawings a line onscreen based on where the user touches
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end {
  dispatch_semaphore_wait(_frameBoundarySemaphore, DISPATCH_TIME_FOREVER);
  [self.commandQueue.commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuffer) {
    dispatch_semaphore_signal(self->_frameBoundarySemaphore);
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
  count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / self.brushSize), 1);
  
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
  renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
  renderPassDescriptor.colorAttachments[0].clearColor = [self clearColorFromColor:[UIColor blackColor]];
  renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
  renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
  
  id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder
  if (!renderEncoder) {
    NSLog(@"renderEncoder fail");
    return;
  }
  
  [renderEncoder setViewport:(MTLViewport){0.0, 0.0, drawable.texture.width, drawable.texture.height, -1.0, 1.0}]; // 设置显示区域
  
  [renderEncoder setRenderPipelineState:self.renderPipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用
  
  // 设置顶点信息
  [renderEncoder setVertexBytes:vertextData length:sizeof(Vertex_t) * vertexCount atIndex:0];
  
  // 传入brushSize尺寸信息
  float brushW = _brushSize * [UIScreen mainScreen].scale;
  [renderEncoder setVertexBytes:&brushW length:sizeof(float) atIndex:1];
  
  // 传入纹理信息
  [renderEncoder setFragmentTexture:self.brushTexture atIndex:0];
  
  UIColor *redColor = [UIColor redColor];
  const CGFloat *components = CGColorGetComponents(redColor.CGColor);
  simd_float4 paintColor = {components[0], components[1], components[2], components[3]};
  [renderEncoder setFragmentBytes:&paintColor length:sizeof(simd_float4) atIndex:0];
  
  [renderEncoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:0 vertexCount:vertexCount];
  
  [renderEncoder endEncoding]; // 结束
  
  //Committing a CommandBuffer
  [commandBuffer presentDrawable:[layer nextDrawable]]; // 显示
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

#pragma mark - Color

- (MTLClearColor)clearColorFromColor:(UIColor *)color {
  if (!color) {
    NSAssert(NO, @"color can be nil");
    return MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
  }
  CGFloat r, g, b, a ;
  BOOL result = [color getRed:&r green:&g blue:&b alpha:&a];
  if (result) {
    return MTLClearColorMake(r, g, b, a);
  } else {
    return MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
  }
}

@end
