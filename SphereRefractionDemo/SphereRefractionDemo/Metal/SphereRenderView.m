//
//  SphereRenderView.m
//  SphereRefractionDemo
//
//  Created by User on 2019/8/7.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "SphereRenderView.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "DHMetalHelper.h"

@interface SphereRenderView () <MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipelineState;

@property (nonatomic, strong) id<MTLTexture> inputTexture;

@property (nonatomic, strong) dispatch_semaphore_t frameBoundarySemaphore;

@end

@implementation SphereRenderView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];
    
    _radius = 0.301;
    _refractiveIndex = 0.71;
    _centerP = CGPointMake(0.5, 0.5);
    
    [self configureMetal];
  }
  return self;
}

#pragma mark - Metal

- (void)configureMetal {
  _device = MTLCreateSystemDefaultDevice();
  NSParameterAssert(_device);
  
  _commandQueue = [_device newCommandQueue];
  
  _computePipelineState = [DHMetalHelper computePipelineStateWithDevice:_device kernelName:@"SphereRefractionKernel"];
  
  _inputTexture = [DHMetalHelper textureWithImage:[UIImage imageNamed:@"img1.jpg"] device:_device usage:MTLTextureUsageShaderRead];
  
  _mtkView = [[MTKView alloc] initWithFrame:self.bounds device:_device];
  [self addSubview:_mtkView];
  
  _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
  _mtkView.framebufferOnly = NO;
  _mtkView.delegate = self;
  
  _frameBoundarySemaphore = dispatch_semaphore_create(3);
}

- (void)render {
  dispatch_semaphore_wait(_frameBoundarySemaphore, DISPATCH_TIME_FOREVER);
  
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  
  id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
  
  [encoder setComputePipelineState:self.computePipelineState];
  
  id<CAMetalDrawable> drawable = self.mtkView.currentDrawable;
  [encoder setTexture:self.inputTexture atIndex:0];
  [encoder setTexture:drawable.texture atIndex:1];

  packed_float2 center = simd_make_float2(_centerP.x, _centerP.y);
 
  [encoder setBytes:&center length:sizeof(packed_float2) atIndex:0];
  [encoder setBytes:&_radius length:sizeof(float) atIndex:1];
  
  [encoder setBytes:&_refractiveIndex length:sizeof(float) atIndex:2];

  MTLSize threadsPerThreadgroup = MTLSizeMake(16, 16, 1);
  MTLSize threadgroupsPerGrid = MTLSizeMake(drawable.texture.width / threadsPerThreadgroup.width, drawable.texture.height / threadsPerThreadgroup.height, 1);
  
  [encoder dispatchThreadgroups:threadgroupsPerGrid
          threadsPerThreadgroup:threadsPerThreadgroup];
  
  [encoder endEncoding];
  
  // Schedule a drawable presentation to occur after the GPU completes its work
  [commandBuffer presentDrawable:self.mtkView.currentDrawable];
  
  __weak dispatch_semaphore_t semaphore = _frameBoundarySemaphore;
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
    // GPU work is complete
    // Signal the semaphore to start the CPU work
    dispatch_semaphore_signal(semaphore);
  }];
  
  // CPU work is complete
  // Commit the command buffer and start the GPU work
  [commandBuffer commit];
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  [self render];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  CGPoint touchP = [[touches anyObject] locationInView:_mtkView];
  CGFloat posX = touchP.x / CGRectGetWidth(_mtkView.frame);
  CGFloat posY = touchP.y / CGRectGetHeight(_mtkView.frame);
  NSLog(@"touch Point : %g, %g", posX, posY);
  _centerP = CGPointMake(posX, posY);
}

@end
