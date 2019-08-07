//
//  RaymarchingViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/8/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "RaymarchingViewController.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "UIViewController+Utils.h"

static const NSUInteger kMaxInflightBuffers = 3;

@interface RaymarchingViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipelineState;

@property (nonatomic, assign) float timer;
@property (nonatomic, assign) BOOL renderComplete;

@property (nonatomic, strong) dispatch_semaphore_t frameBoundarySemaphore;
@property (nonatomic, assign) NSUInteger currentFrameIndex;
// 资源缓存池
@property (nonatomic, strong) NSArray <id <MTLBuffer>>*dynamicDataBuffers;


@end

@implementation RaymarchingViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  
  [self configureMetal];
  
}

- (void)configureMetal {
  self.device = MTLCreateSystemDefaultDevice();
  if (!_device) {
    NSAssert(NO, @"your device don't support metal");
  }
  
  CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.contentRect), CGRectGetWidth(self.contentRect));
  
  self.mtkView = [[MTKView alloc] initWithFrame:frame device:_device];
  [self.view addSubview:_mtkView];
  _mtkView.center = self.view.center;
  _mtkView.delegate = self;
  _mtkView.clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1);
  _mtkView.framebufferOnly = NO; // 允许shader 写入纹理
  _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
  
  self.commandQueue = [_device newCommandQueue];
  
  id<MTLLibrary> library = [_device newDefaultLibrary];
  id<MTLFunction> computeFunc = [library newFunctionWithName:@"reymarchShader"];
  
  NSError *error = nil;
  _computePipelineState = [_device newComputePipelineStateWithFunction:computeFunc error:&error];
  if (error) {
    NSLog(@"creat piplineState error");
  }
  
  _frameBoundarySemaphore = dispatch_semaphore_create(kMaxInflightBuffers);
  
}

- (void)render {
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  id <MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
  if (!commandEncoder) {
    return;
  }
  
  // 设置渲染管线, 调用shader 方法
  [commandEncoder setComputePipelineState:self.computePipelineState];
  
  // 设置输出纹理
  id<MTLTexture> outTexture = self.mtkView.currentDrawable.texture;
  [commandEncoder setTexture:outTexture atIndex:0];
  
  _timer += 0.02;
  id<MTLBuffer> timesBuffer = [_device newBufferWithBytes:&_timer length:sizeof(float) options:MTLResourceCPUCacheModeDefaultCache];
  [commandEncoder setBuffer:timesBuffer offset:0 atIndex:0];
  
  // threadsGroupCount.width * threadsGroupCount.height * threadsGroupCount.depth <= 1024
  MTLSize threadsGroupCount = MTLSizeMake(8, 8, 1);
  MTLSize threadsGroup = MTLSizeMake(outTexture.width / threadsGroupCount.width, outTexture.height / threadsGroupCount.height, 1);
  
  // 设置并发线程。
  [commandEncoder dispatchThreadgroups:threadsGroup threadsPerThreadgroup:threadsGroupCount];
  [commandEncoder endEncoding];
  
  dispatch_semaphore_wait(_frameBoundarySemaphore, DISPATCH_TIME_FOREVER);
  __weak typeof(self) weakSelf = self;
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuffer) {
    dispatch_semaphore_signal(weakSelf.frameBoundarySemaphore);
  }];
  
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
