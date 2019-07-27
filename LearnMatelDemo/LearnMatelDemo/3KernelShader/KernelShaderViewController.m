//
//  KernelShaderViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/27.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "KernelShaderViewController.h"

#import <Metal/Metal.h>
//#import <MetalKit/MetalKit.h>
/**
 MTKView 对CAMetalLayer的封装.
 MTKTextureLoader 加载纹理
 MTKModel 加载一些3d模型
 */

#import "UIViewController+Utils.h"

@interface KernelShaderViewController ()

@property (nonatomic, strong) CAMetalLayer *metalLayer;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLComputePipelineState> pipelineState;

@property (nonatomic, strong) id<CAMetalDrawable> currentDrawable;

@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation KernelShaderViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  self.title = @"kernel Func Demo";
  
  [self buildMetalConfig];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [_displayLink invalidate];
  _displayLink = nil;
}

- (void)dealloc {
  NSLog(@"kernel dealloc");
}

#pragma mark - Metal

- (void)buildMetalConfig {
  [self initializeMetal];
  
  [self setupMetalLayer];
  
  [self setupPipelineState];
  
  _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
  _displayLink.paused = NO;
  
  [self render];
}

- (void)initializeMetal {
  _device = MTLCreateSystemDefaultDevice();
  if (!_device) {
    NSAssert(NO, @"device dont support metal");
  }
  
  _commandQueue = [_device newCommandQueue];
}

- (void)setupMetalLayer {
  _metalLayer = [CAMetalLayer layer];
  
  _metalLayer.bounds = CGRectMake(0, 0, self.screenSize.width, self.screenSize.width);
  _metalLayer.position = self.view.center;
  [self.view.layer addSublayer:_metalLayer];
  
  _metalLayer.device = _device;       //   设置gpu
  _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm; // 设置颜色格式
  _metalLayer.framebufferOnly = NO;
  _metalLayer.contentsScale = [UIScreen mainScreen].scale;
  //  _metalLayer.drawableSize = scale * size;
}

- (void)setupPipelineState {
  id<MTLLibrary> library = [_device newDefaultLibrary];
  id<MTLFunction> kernelFunc = [library newFunctionWithName:@"compute"];
  
  NSError *error = nil;
  _pipelineState = [_device newComputePipelineStateWithFunction:kernelFunc error:&error];
  if (error) {
    NSAssert(NO, @"init pipelineState error");
  }
}

- (void)render {
  if (_currentDrawable) {
    NSLog(@"Previous render pass not completed!");
    return;
  }
  __weak typeof(self) weakSelf = self;
  [self.commandQueue.commandBuffer addCompletedHandler:^void(id<MTLCommandBuffer> cmdBuf){
    // 命令全都执行完之后，将mCurrentDrawable置空，表示可以绘制下面一帧
    weakSelf.currentDrawable = nil;
  }];
  
  _currentDrawable = self.metalLayer.nextDrawable;
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
  if (computeEncoder) {
    [computeEncoder setComputePipelineState:self.pipelineState];
    
    [computeEncoder setTexture:_currentDrawable.texture atIndex:0];
    
    // https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Compute-Ctx/Compute-Ctx.html#//apple_ref/doc/uid/TP40014221-CH6-SW1
    // 以下为设置并发线程。
    // 设置纹理
    MTLSize threadsGroupCount = MTLSizeMake(8, 8, 1);
    MTLSize threadsGroup = MTLSizeMake(_currentDrawable.texture.width / threadsGroupCount.width, _currentDrawable.texture.height / threadsGroupCount.height, 1);

    // 设置并发线程。
    [computeEncoder dispatchThreadgroups:threadsGroup threadsPerThreadgroup:threadsGroupCount];

    [computeEncoder endEncoding];
  }
  
  [commandBuffer presentDrawable:_currentDrawable];
  [commandBuffer commit];
}


@end
