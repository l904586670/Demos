//
//  MirrorViewController.m
//  VideoMirrorDemo
//
//  Created by User on 2019/8/9.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "MirrorViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "DHMetalHelper.h"

typedef NS_ENUM(NSInteger, MirrorType) {
  MirrorTypeVertical = 0, // 垂直镜像, mirrorType 0, 1 内外镜像
  MirrorTypeLeftToRight,
  MirrorTypeDownToUp,
  MirrorTypeDownRightSlice,
  MirrorTypeDownLeftSlice,
  MirrorTypeCenterRightSlice,
  
  MirrorTypeNumber,
};

@interface MirrorViewController ()<MTKViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> texture;

@property (nonatomic, strong) NSMutableArray <id<MTLComputePipelineState>>*cmtPipelineStates;

@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;

@property (nonatomic, strong) AVCaptureSession *mCaptureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *mCaptureDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *mCaptureDeviceOutput;
@property (nonatomic, strong) dispatch_queue_t mProcessQueue;

@property (nonatomic, assign) NSInteger mirrorIndex;

@end

@implementation MirrorViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self configureMetal];
  
  [self setupCaptureSession];
  
  [self setupUI];
}

- (void)setupCaptureSession {
  self.mCaptureSession = [[AVCaptureSession alloc] init];
  self.mCaptureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
  self.mProcessQueue = dispatch_queue_create("mProcessQueue", DISPATCH_QUEUE_SERIAL); // 串行队列
  
  AVCaptureDevice *videoDevice = nil;
  if (@available(iOS 10.2, *)) {
    videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
  }
  if (!videoDevice) {
    videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
  }
  
  self.mCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
  if ([self.mCaptureSession canAddInput:self.mCaptureDeviceInput]) {
    [self.mCaptureSession addInput:self.mCaptureDeviceInput];
  }
  
  self.mCaptureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
  [self.mCaptureDeviceOutput setAlwaysDiscardsLateVideoFrames:NO];
  // 这里设置格式为BGRA，而不用YUV的颜色空间，避免使用Shader转换
  [self.mCaptureDeviceOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
  [self.mCaptureDeviceOutput setSampleBufferDelegate:self queue:self.mProcessQueue];
  if ([self.mCaptureSession canAddOutput:self.mCaptureDeviceOutput]) {
    [self.mCaptureSession addOutput:self.mCaptureDeviceOutput];
  }
  AVCaptureConnection *connection = [self.mCaptureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
  [connection setVideoOrientation:AVCaptureVideoOrientationPortrait]; // 设置方向
  [self.mCaptureSession startRunning];
}

#pragma mark - Metal

- (void)configureMetal {
  _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:MTLCreateSystemDefaultDevice()];
  _mtkView.delegate = self;
  _mtkView.framebufferOnly = NO; // 默认drawable texture 只读, 设为可读写
  [self.view addSubview:_mtkView];
  
  self.commandQueue = [self.mtkView.device newCommandQueue];
  CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
  
  
  id<MTLLibrary> library = [_mtkView.device newDefaultLibrary];
  NSError *error = nil;

  self.cmtPipelineStates = [NSMutableArray array];
  NSArray *kernelNames = @[ @"mirrorKernel", @"leftToRight", @"downToUp", @"downRightSlice", @"downLeftSlice", @"centerRightSlice" ];
  for (NSInteger i = 0; i < MirrorTypeNumber; i++) {
    id<MTLFunction> mirrorFunc = [library newFunctionWithName:kernelNames[i]];
    
    id<MTLComputePipelineState> pipelineState = [_mtkView.device newComputePipelineStateWithFunction:mirrorFunc error:&error];
    if (error) {
      NSAssert(NO, @"creat pipelineState fail : %@", error.localizedDescription);
      break;
    }
    [self.cmtPipelineStates addObject:pipelineState];
  }
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  if (self.texture) {
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer]; // 创建指令缓冲
    id<MTLTexture> drawingTexture = view.currentDrawable.texture; // 把MKTView作为目标纹理
    
    id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
    if (!encoder) {
      self.texture = NULL;
      return;
    }
    [encoder setComputePipelineState:_cmtPipelineStates[_mirrorIndex]];
    
    [encoder setTexture:drawingTexture atIndex:0];
    [encoder setTexture:_texture atIndex:1];
    float mirrorType = 0.0;
    [encoder setBytes:&mirrorType length:sizeof(float) atIndex:0];
  
    MTLSize threadsPerThreadgroup = MTLSizeMake(16, 16, 1);
    MTLSize threadgroupsPerGrid = MTLSizeMake(drawingTexture.width / threadsPerThreadgroup.width, drawingTexture.height / threadsPerThreadgroup.height, 1);
    [encoder dispatchThreadgroups:threadgroupsPerGrid
            threadsPerThreadgroup:threadsPerThreadgroup];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:view.currentDrawable]; // 展示数据
    [commandBuffer commit];
    
    self.texture = NULL;
  }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  
  size_t width = CVPixelBufferGetWidth(pixelBuffer);
  size_t height = CVPixelBufferGetHeight(pixelBuffer);
  
  CVMetalTextureRef tmpTexture = NULL;
  // 如果MTLPixelFormatBGRA8Unorm和摄像头采集时设置的颜色格式不一致，则会出现图像异常的情况；
  CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture);
  if(status == kCVReturnSuccess)
  {
    self.mtkView.drawableSize = CGSizeMake(width, height);
    self.texture = CVMetalTextureGetTexture(tmpTexture);
    CFRelease(tmpTexture);
  }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection API_AVAILABLE(ios(6.0)) {
  
}


#pragma mark - UI

- (void)setupUI {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
  [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [btn setTitle:@"切换" forState:UIControlStateNormal];
  btn.frame = CGRectMake(0, screenSize.height - 50, screenSize.width, 40);
  
  [btn addTarget:self action:@selector(onNextButtonTouch) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:btn];
}

- (void)onNextButtonTouch {
  _mirrorIndex += 1;
  if (_mirrorIndex >= MirrorTypeNumber) {
    _mirrorIndex = 0;
  }
}


@end
