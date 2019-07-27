//
//  PaintingView.m
//  PaintByMetalDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "PaintingView.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "MetalLoadTextureTool.h"
#import "CommonDefinition.h"

@interface PaintingView ()


@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLDevice>               device; // GPU

@property (nonatomic, strong) id<MTLCommandQueue>         commandQueue;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;

@property (nonatomic, strong) id<MTLTexture> paintTexture;
@property (nonatomic, strong) id<MTLTexture> brushTexture;      // 笔刷纹理

@property (nonatomic, assign) BOOL firstTouch;
@property (nonatomic, strong) id<CAMetalDrawable> currentDrawable;

@property (nonatomic, assign) CGPoint location;
@property (nonatomic, assign) CGPoint previousLocation;

@end

@implementation PaintingView

+ (Class)layerClass {
  return [CAMetalLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _bgColor = [UIColor whiteColor];
    _brushSize = 30.0;
    
    [self initiatizeMatel];
    
    [self loadTextureData];
    
    [self setupPipeline];
    
    [self clearPaint];
    
    self.opaque = NO;
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  CAMetalLayer *metalLayer = (CAMetalLayer *)self.layer;
  metalLayer.drawableSize = self.frame.size;
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
  
  CAMetalLayer *metalLayer = (CAMetalLayer *)self.layer;
  
  self.layer.contentsScale = [UIScreen mainScreen].scale;
  metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  metalLayer.opaque = NO;
  metalLayer.device = _device;
  metalLayer.drawableSize = self.frame.size;
  
  metalLayer.framebufferOnly = YES;
  
  // Create a CommandQueue
  _commandQueue = [_device newCommandQueue];
}

- (void)loadTextureData {
  UIImage *brushImage = [UIImage imageNamed:@"Particle.png"];
  if (!brushImage) {
    NSAssert(NO, @"Not find Particle.png");
    return;
  }
  
  _brushTexture = [MetalLoadTextureTool textureWithImage:brushImage device:_device];

  size_t width = CGRectGetWidth(self.frame) * self.layer.contentsScale;
  size_t height = CGRectGetHeight(self.frame) * self.layer.contentsScale;
  
  MTLTextureDescriptor *paintDescriptor = [[MTLTextureDescriptor alloc] init];
  paintDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
  paintDescriptor.width = width;
  paintDescriptor.height = height;
  paintDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
  
  self.paintTexture = [_device newTextureWithDescriptor:paintDescriptor];
}

- (void)setupPipeline {
  id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
  id <MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"vertexPaintShader"];
  id <MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"fragmentPaintShader"];
  
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  
  pipelineStateDescriptor.vertexFunction = vertexFunc;
  pipelineStateDescriptor.fragmentFunction = fragmentFunc;
  // 像素格式要与CAMetalLayer的像素格式一致
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
  
  
//  pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;      // 不启用深度测试
//  pipelineStateDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;    // 不启用stencil
  /*
    // 融合
  pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;   // 是否允许颜色融合
  pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
  pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
  pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorOne;
  pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;
  pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
  pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
   */
  
  NSError *error = nil;
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
  if (error) {
    NSAssert(NO, @"creat pipelineState Error : %@", error.description);
  }
}

#pragma mark - Base Methods

// Drawings a line onscreen based on where the user touches
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end {
  if (_currentDrawable) {
    NSLog(@"Previous render pass not completed!");
    return;
  }
  __weak typeof(self) weakSelf = self;
  [self.commandQueue.commandBuffer addCompletedHandler:^void(id<MTLCommandBuffer> cmdBuf){
    // 命令全都执行完之后，将mCurrentDrawable置空，表示可以绘制下面一帧
    weakSelf.currentDrawable = nil;
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

  MTLRenderPassDescriptor *renderPassDescriptor = [self renderPassDescriptor];
  
  
  id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder
  if (!renderEncoder) {
    NSLog(@"renderEncoder fail");
    return;
  }
  
  
  CAMetalLayer *metalLayer = (CAMetalLayer *)self.layer;
  metalLayer.drawableSize = self.frame.size;
  [renderEncoder setViewport:(MTLViewport){0.0, 0.0, metalLayer.drawableSize.width, metalLayer.drawableSize.height, -1.0, 1.0}]; // 设置显示区域
  
  [renderEncoder setRenderPipelineState:_pipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用
  
  // 设置顶点信息
  [renderEncoder setVertexBytes:vertextData length:sizeof(Vertex_t) * vertexCount atIndex:0];
  
  // 传入brushSize尺寸信息
  [renderEncoder setVertexBytes:&_brushSize length:sizeof(float) atIndex:1];
 
 
  // 传入纹理信息
  [renderEncoder setFragmentTexture:self.brushTexture atIndex:0];

  
  UIColor *redColor = [UIColor redColor];
  const CGFloat *components = CGColorGetComponents(redColor.CGColor);
  simd_float4 paintColor = {components[0], components[1], components[2], components[3]};
  [renderEncoder setFragmentBytes:&paintColor length:sizeof(simd_float4) atIndex:0];
  
  [renderEncoder drawPrimitives:MTLPrimitiveTypePoint vertexStart:0 vertexCount:vertexCount];
  
  [renderEncoder endEncoding]; // 结束
  
  if (!_currentDrawable) {
    NSAssert(NO, @"---error ---");
  }
  
  //Committing a CommandBuffer
  [commandBuffer presentDrawable:_currentDrawable]; // 显示
  [commandBuffer commit];
}

#pragma mark - Public Methods

- (void)clearPaint {
  __weak typeof(self) weakSelf = self;
  [self.commandQueue.commandBuffer addCompletedHandler:^void(id<MTLCommandBuffer> cmdBuf){
    // 命令全都执行完之后，将mCurrentDrawable置空，表示可以绘制下面一帧
    weakSelf.currentDrawable = nil;
  }];
  
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  CAMetalLayer *metalLayer = (CAMetalLayer *)self.layer;
  id<CAMetalDrawable> drawable = metalLayer.nextDrawable;
  _currentDrawable = drawable;
  
  MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  // colorAttachments 用于保存绘图结果并在屏幕上显示
  descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
  descriptor.colorAttachments[0].clearColor = [self clearColorFromColor:_bgColor];
  descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
  descriptor.colorAttachments[0].texture = drawable.texture;
  
  id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor]; //编码绘制指令的Encoder
  if (!renderEncoder) {
    NSLog(@"renderEncoder fail");
    return;
  }
  
  [renderEncoder setViewport:(MTLViewport){0.0, 0.0, metalLayer.drawableSize.width, metalLayer.drawableSize.height, -1.0, 1.0}]; // 设置显示区域
  [renderEncoder endEncoding]; // 结束
  [commandBuffer presentDrawable:_currentDrawable]; // 显示
  [commandBuffer commit];
}

#pragma mark - Private Methods


/// 获取下一帧的drawble以及下一帧渲染遍描述符
/// @preturn 下一帧的渲染遍描述符
- (MTLRenderPassDescriptor *)renderPassDescriptor {
  CAMetalLayer *metalLayer = (CAMetalLayer *)self.layer;
  id<CAMetalDrawable> drawable = metalLayer.nextDrawable;
  _currentDrawable = drawable;
  
  MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  
  /*
   渲染开始时执行的操作.
   MTLLoadActionClear : 在开始前做一次清除操作,所有像素值变为.clearColor中的值
   MTLLoadActionLoad : 保留了纹理的现有内容
   MTLLoadActionDontCare : 渲染开始时像素值为任意值, 允许GPU避免加载纹理的现有内容，从而确保最佳性
   */
  descriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
  // loadAction == MTLLoadActionClear时调用. 为每一个像素点赋值
//  descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1.0f);
  /*
   渲染结束时执行的操作
   MTLStoreActionStore : 将渲染传递的最终结果保存到附件
   
   MTLStoreActionDontCare : 在渲染过程完成后，将附件保留在未定义状态。这可以提高性能，因为它使实现能够避免保留渲染结果所需的任何工作
   */
  descriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
  descriptor.colorAttachments[0].texture = drawable.texture;

  return descriptor;
}

#pragma mark - OverWirte Methods

- (BOOL)canBecomeFirstResponder {
  return YES;
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [[event touchesForView:self] anyObject];
  _firstTouch = YES;
  // Convert touch point from UIView referential to OpenGL one (upside-down flip)
  _location = [touch locationInView:self];
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  
  UITouch *touch = [[event touchesForView:self] anyObject];
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
  UITouch *touch = [[event touchesForView:self] anyObject];
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
