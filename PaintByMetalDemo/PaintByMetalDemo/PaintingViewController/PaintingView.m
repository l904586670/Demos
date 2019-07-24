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

@interface PaintingView () <MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice>               device; // GPU
@property (nonatomic, strong) MTKView                     *mtkView;
@property (nonatomic, assign) vector_uint2                viewportSize;
@property (nonatomic, strong) id<MTLCommandQueue>         commandQueue;
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;


@end

@implementation PaintingView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self initiatizeMatel];
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
  
}

- (void)setupPipeline {
  id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
  id <MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"vertexShaderMain"];
  id <MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"fragmentShaderMain"];
  
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  
  // 描述顶点和颜色位置和偏移量
//  MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
//  vertexDescriptor.attributes[0].offset = 0;
//  vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4; // position
//  vertexDescriptor.attributes[0].bufferIndex = 0;
//
//  vertexDescriptor.attributes[1].offset = sizeof(float) * 4; // 16
//  vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4; // texCoords
//  vertexDescriptor.attributes[1].bufferIndex = 0;
//
//  vertexDescriptor.attributes[2].offset = sizeof(float) * 8;
//  vertexDescriptor.attributes[2].format = MTLVertexFormatFloat2; // texCoords
//  vertexDescriptor.attributes[2].bufferIndex = 0;
//
//  vertexDescriptor.layouts[0].stepRate = 1;
//  vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
//  vertexDescriptor.layouts[0].stride = sizeof(LBVertex);
//
//  pipelineStateDescriptor.vertexDescriptor = vertexDescriptor;
  
  // 顶点描述
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
  pipelineStateDescriptor.vertexFunction = vertexFunc;
  pipelineStateDescriptor.fragmentFunction = fragmentFunc;
  
  NSError *error = nil;
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
  if (error) {
    NSAssert(NO, @"creat pipelineState Error : %@", error.description);
  }
}

#pragma mark - Public Methods




#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  _viewportSize = (vector_uint2){size.width, size.height};
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  
//  [self render];
}


@end
