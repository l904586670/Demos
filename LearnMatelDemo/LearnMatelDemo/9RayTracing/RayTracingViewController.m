//
//  RayTracingViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/8/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "RayTracingViewController.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "UIViewController+Utils.h"
#import "DHMetalHelper.h"

static const NSUInteger kMaxInflightBuffers = 3;

@interface RayTracingViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) id<MTLComputePipelineState> cptPipelineState;
@property (nonatomic, strong) id<MTLTexture> inputTexture;

@property (nonatomic, assign) float timer;
@property (nonatomic, strong) dispatch_semaphore_t frameBoundarySemaphore;

@end

@implementation RayTracingViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self configureMetal];
}

- (void)configureMetal {
  _device = MTLCreateSystemDefaultDevice();
  if (!_device) {
    NSAssert(NO, @"the device don't support metal");
  }
  _commandQueue = [_device newCommandQueue];
  
  _mtkView = [[MTKView alloc] initWithFrame:self.contentRect device:_device];
  [self.view addSubview:_mtkView];
  _mtkView.preferredFramesPerSecond = 60;
  _mtkView.delegate = self;
  _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
  _mtkView.clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1.0);
  _mtkView.framebufferOnly = NO;
  
  _frameBoundarySemaphore = dispatch_semaphore_create(kMaxInflightBuffers);
  
  _cptPipelineState = [DHMetalHelper computePipelineStateWithDevice:_device kernelName:@"reytracing"];
  
  UIImage *image = [UIImage imageNamed:@"img1.jpg"];
  _inputTexture = [DHMetalHelper textureWithImage:image device:_device];
}

- (void)render {
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
  if (!encoder) {
    return;
  }
  
  [encoder setComputePipelineState:_cptPipelineState];
  
  [encoder setTexture:self.mtkView.currentDrawable.texture atIndex:0];
  
  MTLSize threadsGroupCount = MTLSizeMake(8, 8, 1);
  MTLSize threadsGroup = MTLSizeMake(self.mtkView.currentDrawable.texture.width / threadsGroupCount.width, self.mtkView.currentDrawable.texture.height / threadsGroupCount.height, 1);

  [encoder dispatchThreadgroups:threadsGroup
          threadsPerThreadgroup:threadsGroupCount];
  
  [encoder endEncoding];
  [commandBuffer presentDrawable:self.mtkView.currentDrawable];
  [commandBuffer commit];

  dispatch_semaphore_wait(_frameBoundarySemaphore, DISPATCH_TIME_FOREVER);
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuffer) {
    dispatch_semaphore_signal(self->_frameBoundarySemaphore);
  }];

}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  [self render];
}


@end
