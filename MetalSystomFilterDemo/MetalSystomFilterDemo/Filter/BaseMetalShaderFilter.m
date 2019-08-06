//
//  BaseMetalShaderFilter.m
//  MetalSystomFilterDemo
//
//  Created by User on 2019/8/6.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "BaseMetalShaderFilter.h"

#import <Metal/Metal.h>
#import "DHMetalHelper.h"

@interface BaseMetalShaderFilter ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipelineState;

@property (nonatomic, strong) dispatch_semaphore_t frameBoundarySemaphore;
@end

@implementation BaseMetalShaderFilter

+ (instancetype)shareInstance {
  static BaseMetalShaderFilter *instace = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instace = [[BaseMetalShaderFilter alloc] init];
  });
  return instace;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    [self setupDefaultValues];
    
    [self configureMetal];
  }
  return self;
}


#pragma mark - Metal

- (void)configureMetal {
  _device = MTLCreateSystemDefaultDevice();
  if (!_device) {
    NSAssert(NO, @"this device don't support metal");
    return;
  }
  _commandQueue = [_device newCommandQueue];
  
  _computePipelineState = [DHMetalHelper computePipelineStateWithDevice:_device kernelName:@"baseFilterKernel"];
  
  _frameBoundarySemaphore = dispatch_semaphore_create(1); // 当前的纹理处理完在处理下一次
}

#pragma mark - Public Methods

- (UIImage *)filterWithOriginImage:(UIImage *)image {
  if (!image) {
    return nil;
  }
  
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuffer) {
    dispatch_semaphore_signal(self->_frameBoundarySemaphore);
  }];
  
  id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
  if (!computeEncoder) {
    return nil;
  }
  
  id<MTLTexture> inputTexture = [DHMetalHelper textureWithImage:image device:_device usage:MTLTextureUsageShaderRead];
  id<MTLTexture> outputTexture = [DHMetalHelper emptyTextureWithWidth:image.size.width height:image.size.height device:_device usage:MTLTextureUsageShaderWrite];
  
  [computeEncoder setComputePipelineState:_computePipelineState];
  
  [computeEncoder setTexture:inputTexture atIndex:0]; // 输入纹理
  [computeEncoder setTexture:outputTexture atIndex:1]; // 输出纹理

  [computeEncoder setBytes:&_saturation length:sizeof(float) atIndex:0];
  [computeEncoder setBytes:&_contrast length:sizeof(float) atIndex:1];
  [computeEncoder setBytes:&_brightness length:sizeof(float) atIndex:2];
  [computeEncoder setBytes:&_temperature length:sizeof(float) atIndex:3];
  [computeEncoder setBytes:&_alpha length:sizeof(float) atIndex:4];
  
  MTLSize threadsPerThreadgroup = MTLSizeMake(_computePipelineState.threadExecutionWidth, _computePipelineState.maxTotalThreadsPerThreadgroup / _computePipelineState.threadExecutionWidth, 1);
  MTLSize threadgroupsPerGrid = MTLSizeMake((inputTexture.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width, (inputTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height, 1);
  
  /*
   MTLSize threadsGroupCount = MTLSizeMake(16, 16, 1);
   MTLSize threadsGroup = MTLSizeMake(_currentDrawable.texture.width / threadsGroupCount.width, _currentDrawable.texture.height / threadsGroupCount.height, 1);
   */
  
  [computeEncoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
  [computeEncoder endEncoding];
  [commandBuffer commit];

  [commandBuffer waitUntilCompleted];
  
  dispatch_semaphore_wait(_frameBoundarySemaphore, DISPATCH_TIME_FOREVER);
  
  return [DHMetalHelper imageFromTexture:outputTexture];
}

#pragma mark - Setter Methods



#pragma mark - Private Methods

- (void)setupDefaultValues {
  _saturation = 1.0;
  _contrast = 1.0;
  _brightness = 1.0;
  _temperature = 0.0;
  _alpha = 1.0;
}

@end
