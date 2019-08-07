//
//  TripleBufferViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/30.
//  Copyright © 2019 Rock. All rights reserved.
//
// 动态缓冲区数据是指存储在缓冲区中的频繁更新的数据。为避免每帧创建新缓冲区并最大限度地缩短帧之间的处理器空闲时间

#import "TripleBufferViewController.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "UIViewController+Utils.h"
#import "DHMetalHelper.h"

// 缓冲最大个数
static const NSUInteger kMaxInflightBuffers = 3;

@interface TripleBufferViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) id<MTLComputePipelineState> pipelineState;
@property (nonatomic, strong) id<MTLTexture> inputTexture;

@property (nonatomic, assign) float timer;
@property (nonatomic, assign) BOOL renderComplete;

//
@property (nonatomic, strong) dispatch_semaphore_t frameBoundarySemaphore;
@property (nonatomic, assign) NSUInteger currentFrameIndex;
// 资源缓存池
@property (nonatomic, strong) NSArray <id <MTLBuffer>>*dynamicDataBuffers;

@end

@implementation TripleBufferViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _timer = 0.0;
  
  [self configureMetal];

  [self setupPipelineState];
  
  [self loadTexture];
}

- (void)dealloc {
  NSLog(@"dealloc");
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
  _currentFrameIndex = 0;
}

- (void)setupPipelineState {
  id<MTLLibrary> library = [_device newDefaultLibrary];
  id<MTLFunction> computeFunc = [library newFunctionWithName:@"tripleShader"];
  
  NSError *error = nil;
  _pipelineState = [_device newComputePipelineStateWithFunction:computeFunc error:&error];
  if (error) {
    NSLog(@"creat piplineState error");
  }
}

- (void)loadTexture {
  UIImage *image = [UIImage imageNamed:@"img1.jpg"];
  self.inputTexture = [DHMetalHelper textureWithImage:image device:_device];
  
  // Create a FIFO queue of three dynamic data buffers
  // This ensures that the CPU and GPU are never accessing the same buffer simultaneously
//  MTLResourceOptions bufferOptions = MTLResourceCPUCacheModeDefaultCache;
//  NSMutableArray *mutableDynamicDataBuffers = [NSMutableArray arrayWithCapacity:kMaxInflightBuffers];
//  for(int i = 0; i < kMaxInflightBuffers; i++) {
//    // Create a new buffer with enough capacity to store one instance of the dynamic buffer data
//    id<MTLBuffer> dynamicDataBuffer = [_device newBufferWithLength:sizeof(float) options:bufferOptions];
//    [mutableDynamicDataBuffers addObject:dynamicDataBuffer];
//  }
//  _dynamicDataBuffers = [mutableDynamicDataBuffers copy];
}

- (void)renderDynamic {
  // Wait until the inflight command buffer has completed its work
  dispatch_semaphore_wait(_frameBoundarySemaphore, DISPATCH_TIME_FOREVER);
  
  // Update the per-frame dynamic buffer data
  // Advance the current frame index, which determines the correct dynamic data buffer for the frame
  _currentFrameIndex = (_currentFrameIndex + 1) % kMaxInflightBuffers;
  
  // Update the contents of the dynamic data buffer
  _timer += 0.03;
//  id<MTLBuffer> dynamicBuffer = _dynamicDataBuffers[_currentFrameIndex];
//  memcpy(dynamicBuffer.contents, &_timer, sizeof(float));

  
  // Create a command buffer and render command encoder
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuffer) {
    dispatch_semaphore_signal(self->_frameBoundarySemaphore);
  }];
  
  id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];

  [encoder setComputePipelineState:self.pipelineState];
  
  id<CAMetalDrawable> drawable = self.mtkView.currentDrawable;
  [encoder setTexture:drawable.texture atIndex:0];
  [encoder setTexture:self.inputTexture atIndex:1];
  
  id<MTLBuffer> dynamicBuffer = [_device newBufferWithBytes:&_timer length:sizeof(float) options:MTLResourceCPUCacheModeDefaultCache];
  [encoder setBuffer:dynamicBuffer offset:0 atIndex:0];
  
  MTLSize threadsGroupCount = MTLSizeMake(8, 8, 1);
  MTLSize threadsGroup = MTLSizeMake(drawable.texture.width / threadsGroupCount.width, drawable.texture.height / threadsGroupCount.height, 1);
  
  // 设置并发线程。
  [encoder dispatchThreadgroups:threadsGroup
          threadsPerThreadgroup:threadsGroupCount];
  
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

// 单次渲染
- (void)renderSingle {
  if (_renderComplete) {
    NSLog(@"buffer not render complete");
    return;
  }
  _renderComplete = YES;
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  __weak typeof(self) weakSelf = self;
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmb) {
    weakSelf.renderComplete = NO;
  }];
  
  id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
  if (!encoder) {
    _renderComplete = NO;
    return;
  }
  
  [encoder setComputePipelineState:self.pipelineState];
  
  id<CAMetalDrawable> drawable = self.mtkView.currentDrawable;
  [encoder setTexture:drawable.texture atIndex:0];
  [encoder setTexture:self.inputTexture atIndex:1];
  
  _timer += 0.01;
  id<MTLBuffer> timesBuffer = [_device newBufferWithBytes:&_timer length:sizeof(float) options:MTLResourceCPUCacheModeDefaultCache];
  [encoder setBuffer:timesBuffer offset:0 atIndex:0];
  
  
  MTLSize threadsGroupCount = MTLSizeMake(8, 8, 1);
  MTLSize threadsGroup = MTLSizeMake(drawable.texture.width / threadsGroupCount.width, drawable.texture.height / threadsGroupCount.height, 1);
  
  // 设置并发线程。
  [encoder dispatchThreadgroups:threadsGroup
          threadsPerThreadgroup:threadsGroupCount];
  
  [encoder endEncoding];
  
  [commandBuffer presentDrawable:self.mtkView.currentDrawable];
  [commandBuffer commit];
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  
}

- (void)drawInMTKView:(nonnull MTKView *)view {
//  [self renderSingle];
  
  [self renderDynamic];
}

@end
