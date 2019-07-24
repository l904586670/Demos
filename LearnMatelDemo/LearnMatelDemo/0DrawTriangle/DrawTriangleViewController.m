//
//  DrawTriangleViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/20.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "DrawTriangleViewController.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "Common.h"

@interface DrawTriangleViewController ()<MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLBuffer> vertices;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property (nonatomic, assign) NSUInteger numVertices;

@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;

@property (nonatomic, assign) NSTimeInterval time;

@property (nonatomic, assign) BOOL addMatrix;

@end

@implementation DrawTriangleViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
  
  // 1. 初始化环境
  [self initiatizeMatel];
  
  // 2. 加载模型
  [self loadModel];
  
  // 3. 设置渲染管道
  [self setupPipeline];
}

#pragma mark - UI

- (void)setupUI {
  UISwitch *matrixSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
  [matrixSwitch addTarget:self action:@selector(onMatrixSwitch:) forControlEvents:UIControlEventValueChanged];
  
  UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:matrixSwitch];
  self.navigationItem.rightBarButtonItem = item;
}

#pragma mark - Metal

/**
 初始化GPU设备, 检测当前设备支不支持Metal.
 创建command Queue(异步串行线程). 用于获取当前的 commandBuffer 并提交给GPU
 创建 MTKView 显示内容
 */
- (void)initiatizeMatel {
  // get the Dvice
  self.device = MTLCreateSystemDefaultDevice();
  if (!_device) {
    NSAssert(NO, @"current device GPU not support Metal");
  } else {
    NSLog(@"current GPU name : %@", _device.name);
  }
  
  // Create a CommandQueue
  self.commandQueue = [self.device newCommandQueue];
  
  self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:_device];
  self.mtkView.clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1.0);
  self.mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
  self.mtkView.delegate = self;
  [self.view addSubview:self.mtkView];
}


/**
 加载顶点数据
 */
- (void)loadModel {
  // x, y, z, w,   r, g, b, a,
  static const float vertex[] = {
    0.5,  -0.5, 0.0, 1.0,  1.0,   0,  0,  1,
    -0.5, -0.5, 0.0, 1.0,  0.0, 1.0,  0,  1,
    0,     0.5, 0.0, 1.0,  0.0, 0.0, 1.0, 1,
  };
  
  self.vertices = [_device newBufferWithBytes:vertex length:sizeof(vertex) options:0];
  self.numVertices = sizeof(vertex) / (sizeof(float) * 8);
}


/**
 创建渲染管道对象, 首先获取vertex shader 和 fragment shader
 创建渲染管道描述符, 描述顶点坐标的信息(Postion, color, texture..)
 加载 shader 方法, 确定frameBuffer format
 */
- (void)setupPipeline {
  id <MTLLibrary> defaultLibrary = [self.device newDefaultLibrary];
  id <MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"vertexShader"];
  id <MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"fragmentShader"];

  // Render Pipeline Descriptors 渲染管道描述符
  /*
  Vertex Layout
  Descriptor
  Vertex Shader
  Fragment Shader
  Blending
  Framebuffer Formats
   */
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  
  // 描述顶点和颜色位置和偏移量
  MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
  vertexDescriptor.attributes[0].offset = 0;
  vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4; // position
  vertexDescriptor.attributes[0].bufferIndex = 0;
  
  vertexDescriptor.attributes[1].offset = sizeof(float) * 4; // 16
  vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4; // normal
  vertexDescriptor.attributes[1].bufferIndex = 0;
  
  // 如果有纹理信息, 添加纹理信息
//  vertexDescriptor.attributes[2].offset = 24;
//  vertexDescriptor.attributes[2].format = MTLVertexFormatFloat2; // texCoords
//  vertexDescriptor.attributes[2].bufferIndex = 0;
  
  vertexDescriptor.layouts[0].stepRate = 1;
  vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
  vertexDescriptor.layouts[0].stride = sizeof(float) * 8;

  pipelineStateDescriptor.vertexDescriptor = vertexDescriptor;

  // 顶点描述
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
  pipelineStateDescriptor.vertexFunction = vertexFunc;
  pipelineStateDescriptor.fragmentFunction = fragmentFunc;
  
  NSError *error = nil;
  self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
  if (error) {
    NSAssert(NO, @"creat pipelineState Error : %@", error.description);
  }
}

/**
 渲染, 获取 commandBuffer , 创建渲染描述符
 创建渲染编码器, 设置数据,确定绘画类型,结束编码
 加载到currentDrawAble上. 提交此次buffer
 */
- (void)render {
  // Get a command buffer 每次渲染都要单独创建一个CommandBuffer
  id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
  
  // Start a Render Pass
  MTLRenderPassDescriptor *renderPassDescriptor = [self.mtkView currentRenderPassDescriptor];
  /*
   MTLRenderPassDescriptor
   Color Attachment 0
   Color Attachment 1
   Color Attachment 2
   Color Attachment 3
   Depth Attachment
   Stencil Attachment
   */
//  MTLRenderPassDescriptor描述一系列attachments的值，类似GL的FrameBuffer；同时也用来创建MTLRenderCommandEncoder
  if(renderPassDescriptor) {

//    renderPassDescriptor.colorAttachments[0].texture = self.mtkView.currentDrawable.texture;
//    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0f); // 设置默认颜色
    
    // Draw
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder
//    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, self.viewportSize.x, self.viewportSize.y, -1.0, 1.0 }]; // 设置显示区域
    [renderEncoder setRenderPipelineState:self.pipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用

    // 把数据传给顶点描述shader 方法, self.vertices 整个数据内容. offset 偏移, atIndex 设置的buffer 索引, 设为0对应vertex shader 里面的 [[ buffer(0) ]] . 从0 开始
    [renderEncoder setVertexBuffer:self.vertices
                            offset:0
                           atIndex:0]; // 设置顶点缓存
    
    Uniforms uni_matrix = {[self getMetalMatrix]};
    
    [renderEncoder setVertexBytes:&uni_matrix length:sizeof(Uniforms) atIndex:1];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:self.numVertices]; // 绘制
    
    [renderEncoder endEncoding]; // 结束
    
    //Committing a CommandBuffer
    [commandBuffer presentDrawable:self.mtkView.currentDrawable]; // 显示
    [commandBuffer commit];
  } else {
    
    // Commit the command buffer
    [commandBuffer commit]; // 提交；
  }
}

#pragma mark - Switch Action

- (void)onMatrixSwitch:(UISwitch *)sender {
  _addMatrix = sender.on;
  
  
}

#pragma mark - Private Methods

- (matrix_float4x4)getMetalMatrix {
  _time += 0.05;
  CGFloat dx = sin(_time);
  CGFloat dy = cos(_time);
  if (!_addMatrix) {
    dx = 0;
    dy = 0;
  }
  
  matrix_float4x4 ret = (matrix_float4x4){
    simd_make_float4(1, 0, 0, dx),
    simd_make_float4(0, 1, 0, dy),
    simd_make_float4(0, 0, 1, 0),
    simd_make_float4(0, 0, 0, 1),
  };
  return ret;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  [self render];
}

@end
