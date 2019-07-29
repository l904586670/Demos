//
//  SphereLightViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/29.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "SphereLightViewController.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "UIViewController+Utils.h"
#import "MetalLoadTextureTool.h"

@interface SphereLightViewController () <MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) MTKView *mtkView;

@property (nonatomic, strong) NSMutableArray <id<MTLComputePipelineState>>* pipelineStates;
@property (nonatomic, assign) BOOL renderComplete;
@property (nonatomic, assign) float times;
@property (nonatomic, assign) NSInteger segIndex;

@property (nonatomic, strong) id<MTLTexture> texture;

@end

@implementation SphereLightViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];
  self.pipelineStates = [NSMutableArray array];
  
  [self buildMetalConfig];
  
  [self setupUI];
}

#pragma mark - UI

- (void)setupUI {
  CGFloat posY = CGRectGetMinY(self.contentRect);
  
  CGRect frame = CGRectMake(0, posY, self.screenSize.width, 50);
  frame = CGRectInset(frame, 2, 2);
  
  UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"光照", @"噪点", @"纹理"]];
  segmentControl.frame = frame;
  [self.view addSubview:segmentControl];
  _segIndex = 0;
  segmentControl.selectedSegmentIndex = _segIndex;
  [segmentControl addTarget:self
                     action:@selector(onItem:)
           forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Metal

- (void)buildMetalConfig {
  [self initializeMetal];
  
  [self setupPipelineState];
  
  [self setupTexture];
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
  CGRect frame = CGRectMake(0, 0, self.screenSize.width, self.screenSize.width);
  _mtkView = [[MTKView alloc] initWithFrame:frame device:_device];
  [self.view addSubview:_mtkView];
  _mtkView.center = self.view.center;
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
  
  id<MTLFunction> lightFunc = [library newFunctionWithName:@"lightCompute"];
  NSError *error = nil;
  
  _pipelineStates[0] = [_device newComputePipelineStateWithFunction:lightFunc error:&error];
  if (error) {
    NSAssert(NO, @"creat ComputePipelineState error");
  }
  
  id<MTLFunction> noseFunc = [library newFunctionWithName:@"noseCompute"];
  _pipelineStates[1] = [_device newComputePipelineStateWithFunction:noseFunc error:&error];
  if (error) {
    NSAssert(NO, @"creat ComputePipelineState error");
  }
  
  id<MTLFunction> textureFunc = [library newFunctionWithName:@"textureCompute"];
  _pipelineStates[2] = [_device newComputePipelineStateWithFunction:textureFunc error:&error];
  if (error) {
    NSAssert(NO, @"creat ComputePipelineState error");
  }
}

- (void)setupTexture {
  UIImage *image = [UIImage imageNamed:@"texture.jpg"];
  if (!image) {
    NSAssert(NO, @"creat image fail, name [texture.jpg]");
  }
//  NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"img1" ofType:@"jpg"];
  // MTKTextureLoader 加载出的图片
//  MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
//  _texture = [textureLoader newTextureWithCGImage:image.CGImage options:nil error:nil];
  
  _texture = [MetalLoadTextureTool textureWithImage:image device:_device];
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
  [commandEncoder setComputePipelineState:_pipelineStates[_segIndex]];
  
  // 设置输出纹理
  id<MTLTexture> outTexture = self.mtkView.currentDrawable.texture;
  [commandEncoder setTexture:outTexture atIndex:0];
  
  _times += 0.01;
  id<MTLBuffer> timesBuffer = [_device newBufferWithBytes:&_times length:sizeof(float) options:MTLResourceCPUCacheModeDefaultCache];
  [commandEncoder setBuffer:timesBuffer offset:0 atIndex:0];
  
  if (_segIndex == 2) {
    [commandEncoder setTexture:self.texture atIndex:1];
  }
  
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

#pragma mark - Button Action

- (void)onItem:(UISegmentedControl *)sender {
  NSInteger index = sender.selectedSegmentIndex;
  
  _segIndex = index;
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  [self render];
}

@end
