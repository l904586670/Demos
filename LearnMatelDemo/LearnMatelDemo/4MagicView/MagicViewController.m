//
//  MagicViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/29.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "MagicViewController.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "UIViewController+Utils.h"

@interface MagicViewController () <MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLComputePipelineState> pipelineState;

@property (nonatomic, assign) float times;
@property (nonatomic, assign) BOOL renderComplete;

@end

@implementation MagicViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  
  [self buildMetalConfig];
}

#pragma mark - Metal

- (void)buildMetalConfig {
  [self initializeMetal];
  
  [self setupPipelineState];
}

- (void)initializeMetal {
  self.device = MTLCreateSystemDefaultDevice();
  if (!_device) {
    NSAssert(NO, @"device don't support metal");
    return;
  }
  
  //
  _commandQueue = [_device newCommandQueue];
  
  //
  _mtkView = [[MTKView alloc] initWithFrame:self.contentRect device:_device];
  [self.view addSubview:_mtkView];
  _mtkView.delegate = self;
  _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
  _mtkView.clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1.0);
  _mtkView.framebufferOnly = NO;  // 在使用Kernel 方法时.不能设为YES.default -> YES
  
  // 手动调用 draw方法时
//  _mtkView.paused = YES;
//  _mtkView.enableSetNeedsDisplay = NO;
}

- (void)setupPipelineState {
  id<MTLLibrary> library = [_device newDefaultLibrary];
  
  id<MTLFunction> kernelFunc = [library newFunctionWithName:@"magicCompute"];
  
  NSError *error = nil;
  self.pipelineState = [_device newComputePipelineStateWithFunction:kernelFunc error:&error];
  if (error) {
    NSAssert(NO, @"creat ComputePipelineState error");
  }
}

- (void)render {
  if (_renderComplete) {
    NSLog(@"render don't complete");
    return;
  }
  
  _renderComplete = YES;
  __weak typeof(self) weakSelf = self;
  
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuf) {
//    __strong __typeof(self) strongSelf = weakSelf;
    weakSelf.renderComplete = NO;
//    NSLog(@"renderComplete : %@", @(strongSelf.renderComplete));
  }];
  
  id <MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
  if (!commandEncoder) {
    _renderComplete = NO;
    return;
  }
  
  // 设置渲染管线, 调用shader 方法
  [commandEncoder setComputePipelineState:self.pipelineState];
  
  // 设置输出纹理
  id<MTLTexture> outTexture = self.mtkView.currentDrawable.texture;
  [commandEncoder setTexture:outTexture atIndex:0];

  _times += 0.01;
  id<MTLBuffer> timesBuffer = [_device newBufferWithBytes:&_times length:sizeof(float) options:MTLResourceCPUCacheModeDefaultCache];
  [commandEncoder setBuffer:timesBuffer offset:0 atIndex:0];
 
  // threadsGroupCount.width * threadsGroupCount.height * threadsGroupCount.depth <= 1024
  MTLSize threadsGroupCount = MTLSizeMake(8, 8, 1);
  MTLSize threadsGroup = MTLSizeMake(outTexture.width / threadsGroupCount.width, outTexture.height / threadsGroupCount.height, 1);
  
  // 设置并发线程。
  [commandEncoder dispatchThreadgroups:threadsGroup threadsPerThreadgroup:threadsGroupCount];
  [commandEncoder endEncoding];
  
  //
  [commandBuffer presentDrawable:self.mtkView.currentDrawable];
  [commandBuffer commit];
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  [self render];
}


@end
