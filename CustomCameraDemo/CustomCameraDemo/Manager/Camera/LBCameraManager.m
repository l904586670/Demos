//
//  LBCameraManager.m
//  CustomCameraDemo
//
//  Created by Rock on 2019/8/12.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "LBCameraManager.h"

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <Photos/PHPhotoLibrary.h>

#import "DHCameraHelper.h"
#import "DHVideoBufferWriter.h"

static const NSString *LBCameraAdjustingExposeureContext = @"LBCameraAdjustingExposeureContext";

@interface LBCameraManager () <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,
                               AVCapturePhotoCaptureDelegate>

// 在build setting中设置不能旋转. 用 UIDevice 获取方向不准确,使用陀螺仪获取方向

@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) AVCaptureSession *captureSession;

// 当前活跃设备的输入源
@property (nonatomic, strong) AVCaptureDeviceInput *activeVideoInput;

@property (nonatomic, assign) NSInteger cameraCount;


/***  图片相关  ***/

// 图片的输出会话
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;

// 图片的输出设置
@property (nonatomic, strong) AVCapturePhotoSettings *photoSettings;

// 拍照
@property (nonatomic, assign) LBCapturePhotoType takePhotoType;
@property (nonatomic, copy) CapturePhotoBlock capturePhotoBlock;
@property (nonatomic, strong) NSData *livePhotoData;

/*** 视频相关 ***/

// 视频数据输出, 输出为CMBuffer, 可以用此方法添加实时滤镜之类
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;
@property (nonatomic, assign) BOOL recording;

@property (nonatomic, strong) DHVideoBufferWriter *bufferWriter;

@end

@implementation LBCameraManager

#pragma mark - Lifecycle

- (instancetype)init {
  if (self = [super init]) {
    _flashMode = AVCaptureFlashModeOff;
    _highResolutionEnabled = NO;
    
    [self bufferWriter];
    
    [self videoQueue];
  }
  return self;
}

#pragma mark - Lazy Methods

- (dispatch_queue_t)videoQueue {
  if (!_videoQueue) {
    NSString *label = [[NSBundle mainBundle].bundleIdentifier stringByAppendingString:@".avfoundation.videoQueue"];
    _videoQueue = dispatch_queue_create([label cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
  }
  return _videoQueue;
}

- (AVCaptureSession *)captureSession {
  if (!_captureSession) {
    _captureSession = [[AVCaptureSession alloc] init];

    // 默认给一个高配置
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
      _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    } else if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
      _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    } else {
      _captureSession.sessionPreset = AVCaptureSessionPresetLow;
    }
    _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;

  }
  return _captureSession;
}

- (AVCapturePhotoOutput *)photoOutput {
  if (!_photoOutput) {
    _photoOutput = [[AVCapturePhotoOutput alloc] init];
//    [_photoOutput setPhotoSettingsForSceneMonitoring:self.photoSettings];
  }
  return _photoOutput;
}

- (AVCaptureVideoDataOutput *)videoDataOutput {
  if (!_videoDataOutput) {
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    _videoDataOutput.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    
    [_videoDataOutput setSampleBufferDelegate:self queue:self.videoQueue];
  }
  return _videoDataOutput;
}

- (AVCaptureAudioDataOutput *)audioDataOutput {
  if (!_audioDataOutput) {
    _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioDataOutput setSampleBufferDelegate:self queue:self.videoQueue];
  }
  return _audioDataOutput;
}

- (DHVideoBufferWriter *)bufferWriter {
  if (!_bufferWriter) {
    _bufferWriter = [[DHVideoBufferWriter alloc] init];
  }
  return _bufferWriter;
}

#pragma mark - Setter Getter

- (AVCaptureTorchMode)torchMode {
  return [[self acticeCamera] torchMode];
}

- (void)setTorchMode:(AVCaptureTorchMode)torchMode {
  AVCaptureDevice *device = [self acticeCamera];

  if ([device isTorchModeSupported:torchMode]) {
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
      device.torchMode = torchMode;
      [device unlockForConfiguration];
    } else {
      NSAssert(NO, @"set torch fail : %@", error.localizedDescription);
    }
  }
}

#pragma mark - Public Methods

- (BOOL)setupSessionWithSinglePhoto:(BOOL)photo {
  // 设置摄像头
  NSError *error = nil;
  AVCaptureDevice *videoDevice = [DHCameraHelper videoDeviceWithDevicePosition:AVCaptureDevicePositionBack];
  
  AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
  if (error) {
    NSAssert(NO, @"creat videoInput Error : %@", error.localizedDescription);
    return NO;
  }
  
  // 添加视频流输入
  if ([self.captureSession canAddInput:videoInput]) {
    [self.captureSession addInput:videoInput];
    self.activeVideoInput = videoInput;
  }
  
  // 添加照片输出
  if ([self.captureSession canAddOutput:self.photoOutput]) {
    [self.captureSession addOutput:self.photoOutput];
  }
  
  if (!photo) {
    // 设置麦克风
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (error) {
      NSAssert(NO, @"Get audio Input error : %@", error.localizedDescription);
      return NO;
    }
    if ([self.captureSession canAddInput:audioInput]) {
      [self.captureSession addInput:audioInput];
    }
    
    // 添加视频输入流
    if ([self.captureSession canAddOutput:self.videoDataOutput]) {
      [self.captureSession addOutput:self.videoDataOutput];
    }
    if ([self.captureSession canAddOutput:self.audioDataOutput]) {
      [self.captureSession addOutput:self.audioDataOutput];
      self.audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
    }
  }
  
  return YES;
}

- (void)setSessionPreset:(AVCaptureSessionPreset)sessionPreset {
  if ([self.captureSession canSetSessionPreset:sessionPreset]) {
    self.captureSession.sessionPreset = sessionPreset;
  }
}

- (void)startSession {
  if (![self.captureSession isRunning]) {
    dispatch_async(self.videoQueue, ^{
      [self.captureSession startRunning];
    });
  }
}

- (void)stopSession {
  if ([self.captureSession isRunning]) {
    dispatch_async(self.videoQueue, ^{
      [self.captureSession stopRunning];
    });
  }
}

- (void)capturePhoto:(CapturePhotoBlock)completeHandler {
  self.capturePhotoBlock = completeHandler;
  self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
  // 需要每次生成.
  AVCapturePhotoSettings *setting = [self generalSetting];
  [self.photoOutput capturePhotoWithSettings:setting delegate:self];
}

- (BOOL)canSwitchCameras {
  return self.cameraCount > 1;
}

- (BOOL)switchCameras {
  if (![self canSwitchCameras]) {
    return NO;
  }

  NSError *error = nil;
  AVCaptureDevice *videoDevice = [self inactiveCamera];
  AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

  if (videoInput) {
    [self.captureSession beginConfiguration];

    [self.captureSession removeInput:self.activeVideoInput];

    if ([self.captureSession canAddInput:videoInput]) {
      [self.captureSession addInput:videoInput];
      self.activeVideoInput = videoInput;
    } else {
      [self.captureSession addInput:self.activeVideoInput];
    }

    [self.captureSession commitConfiguration];

    return YES;
  } else {
    return NO;
  }
}


// Tap Methods
- (void)focusAtPoint:(CGPoint)point {
  AVCaptureDevice *device = [self acticeCamera];

  if (device.isFocusPointOfInterestSupported &&
      [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
      device.focusPointOfInterest = point;
      device.focusMode = AVCaptureFocusModeAutoFocus;
      [device unlockForConfiguration];
    } else {
      NSAssert(NO, @"focus fail : %@", error.localizedDescription);
    }
  }
}

- (void)exposeAtPoint:(CGPoint)point {
  AVCaptureDevice *device = [self acticeCamera];
  AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;

  if (device.isExposurePointOfInterestSupported &&
      [device isExposureModeSupported:exposureMode]) {
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
      device.exposurePointOfInterest = point;
      device.exposureMode = exposureMode;

      if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
        [device addObserver:self
                 forKeyPath:@"adjustingExposure"
                    options:NSKeyValueObservingOptionNew
                    context:&LBCameraAdjustingExposeureContext];
      }

      [device unlockForConfiguration];
    } else {
      NSAssert(NO, @"expose fail : %@", error.localizedDescription);
    }
  }
}
- (void)resetFocusAndExposureModes {
  AVCaptureDevice *device = [self acticeCamera];

  AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
  BOOL canResetFocus = [device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode];

  AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
  BOOL canResetExposure = [device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode];

  CGPoint centerPoint = CGPointMake(0.5f, 0.5f);
  NSError *error = nil;

  if ([device lockForConfiguration:&error]) {
    if (canResetFocus) {
      device.focusMode = focusMode;
      device.focusPointOfInterest = centerPoint;
    }

    if (canResetExposure) {
      device.exposureMode = exposureMode;
      device.exposurePointOfInterest = centerPoint;
    }

    [device unlockForConfiguration];
  }
}

- (void)videoZoomWithFactor:(CGFloat)factor {
  AVCaptureDevice *device = [self acticeCamera];
  if (factor < 1.0 || factor > device.activeFormat.videoMaxZoomFactor) {
    NSAssert(NO, @"Video zoom factor out [1, activeFormat.videoMaxZoomFactor]");
  }

  factor = MAX(1, factor);
  factor = MIN(factor, device.activeFormat.videoMaxZoomFactor);

  NSError *error = nil;
  if ([device lockForConfiguration:&error]) {
    device.videoZoomFactor = factor;
    [device unlockForConfiguration];
  }
}

#pragma mark - Video Recorder

- (void)startRecording {
  self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
  if (_recording) {
    return;
  }
  
  AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
  self.videoConnection = videoConnection;
  
  // 视频方向
  if ([videoConnection isVideoOrientationSupported]) {
    videoConnection.videoOrientation = [self currentVideoOrientation];
  }

  AVCaptureDevice *device = [self acticeCamera];
  // 视频 HDR (高动态范围图像)
//  device.videoHDREnabled = YES;
//  device.automaticallyAdjustsVideoHDREnabled = YES;
  // 摄像头镜像
  AVCaptureDevicePosition currentPosition = device.position;
  videoConnection.videoMirrored = ((AVCaptureDevicePositionUnspecified == currentPosition) ||
                                   (AVCaptureDevicePositionFront == currentPosition));
  
  // 视频防抖
  // Cinematic 电影级别的防抖. Standard 一般
  AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeAuto;
  if ([device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
    [videoConnection setPreferredVideoStabilizationMode:stabilizationMode];
  }
  
  // 高帧率模式
  NSError *error = nil;
  CMTime frameDuration = CMTimeMake(1, 60);
  NSArray *supportedFrameRateRanges = [device.activeFormat videoSupportedFrameRateRanges];
  BOOL frameRateSupported = NO;
  
  for (AVFrameRateRange *range in supportedFrameRateRanges) {
    if (CMTIME_COMPARE_INLINE(frameDuration, >=, range.minFrameDuration) &&
        CMTIME_COMPARE_INLINE(frameDuration, <=, range.maxFrameDuration)) {
      frameRateSupported = YES;
    }
  }
  
  if (frameRateSupported && [device lockForConfiguration:&error]) {
    [device setActiveVideoMaxFrameDuration:frameDuration];
    [device setActiveVideoMinFrameDuration:frameDuration];
    [device unlockForConfiguration];
  }

  // 视频平稳对焦
  if ([device isSmoothAutoFocusSupported]) {
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
      device.smoothAutoFocusEnabled = YES;
      [device unlockForConfiguration];
    } else {
      NSAssert(NO, @"start recode error : %@", error.localizedDescription);
    }
  }
  
  _recording = YES;
  [self.bufferWriter startWrite];
}

- (void)stopRecording {
  _recording = NO;
  [self.bufferWriter stopWrite:^(NSURL * _Nullable outputUrl, NSError * _Nullable error) {
    
  }];
}

- (BOOL)isRecording {
  return _recording;
}

#pragma mark - Video Methods


#pragma mark - KVO Action

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if (context == &LBCameraAdjustingExposeureContext) {
    AVCaptureDevice *device = (AVCaptureDevice *)object;

    if (!device.isAdjustingExposure &&
        [device isExposureModeSupported:AVCaptureExposureModeLocked]) {
      [object removeObserver:self
                  forKeyPath:@"adjustingExposure"
                     context:&LBCameraAdjustingExposeureContext];

      dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
          device.exposureMode = AVCaptureExposureModeLocked;
          [device unlockForConfiguration];
        } else {
          NSAssert(NO, @"Exposure fail : %@", error.localizedDescription);
        }
      });
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark - Private Methods

// 返回设备的广角摄像头的个数. 后置双摄为一个广角一个长焦.前置摄像头为广角
- (NSInteger)cameraCount {
  AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
  return session.devices.count;
}

// 获取活跃视频输入源设备
- (AVCaptureDevice *)acticeCamera {
  return self.activeVideoInput.device;
}

- (AVCaptureDevice *)inactiveCamera {
  if (self.cameraCount > 1) {
    if ([self acticeCamera].position == AVCaptureDevicePositionBack) {
      return [self cameraWithPosition:AVCaptureDevicePositionFront];
    } else {
      return [self cameraWithPosition:AVCaptureDevicePositionBack];
    }
  }

  return nil;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)devicePosition {
  AVCaptureDevice *device = nil;
  if (devicePosition == AVCaptureDevicePositionBack) {
    if (@available(iOS 10.2, *)) {
      AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDualCamera] mediaType:AVMediaTypeVideo position:devicePosition];
      device = [discoverySession.devices firstObject];
    }

    // 不支持后置双摄给一个默认的广角摄像头
    if (!device) {
      device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:devicePosition];
    }
  } else if (devicePosition == AVCaptureDevicePositionFront) {
    device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:devicePosition];
  }
  return device;
}

- (AVCaptureVideoOrientation)currentVideoOrientation {
  // 在手机设施了竖排方向锁定后. 返回都是 UIDeviceOrientationPortrait 
  AVCaptureVideoOrientation result;
  UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
  switch (deviceOrientation) {
    case UIDeviceOrientationPortrait:
    case UIDeviceOrientationFaceUp:
    case UIDeviceOrientationFaceDown:
      result = AVCaptureVideoOrientationPortrait;
      break;
    case UIDeviceOrientationPortraitUpsideDown:
      //如果这里设置成AVCaptureVideoOrientationPortraitUpsideDown，则视频方向和拍摄时的方向是相反的。
      result = AVCaptureVideoOrientationPortrait;
      break;
    case UIDeviceOrientationLandscapeLeft:
      result = AVCaptureVideoOrientationLandscapeRight;
      break;
    case UIDeviceOrientationLandscapeRight:
      result = AVCaptureVideoOrientationLandscapeLeft;
      break;
    default:
      result = AVCaptureVideoOrientationPortrait;
      break;
  }
  return result;
}

- (AVCapturePhotoSettings *)generalSetting {
  AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
  if (@available(iOS 12.0, *)) {
    // 闪光灯时自动防红眼
    settings.autoRedEyeReductionEnabled = YES;
  }
  
  if ([settings isHighResolutionPhotoEnabled]) {
    settings.highResolutionPhotoEnabled = _highResolutionEnabled; // 以当前活跃设备和支持的最高分辨率拍照. default = NO
  }
  
  if (@available(iOS 11.0, *)) {
    if ([self.photoOutput isCameraCalibrationDataDeliverySupported]) {
      settings.cameraCalibrationDataDeliveryEnabled = NO;
    }
  }
  
  // 自动图像稳定
  settings.autoStillImageStabilizationEnabled = YES;
  if (@available(iOS 10.2, *)) {
    if ([settings isAutoDualCameraFusionEnabled]) {
      // 自动组合双摄像头设备数据
      settings.autoDualCameraFusionEnabled = YES;
    }
  }
  settings.flashMode = self.flashMode;
  return settings;
}

/**
 无损格式图片导出设置

 @return AVCapturePhotoSettings 实例
 */
- (AVCapturePhotoSettings *)rawPhotoSetting {
  self.photoOutput.livePhotoCaptureEnabled = NO;
  NSUInteger rawFormat = self.photoOutput.availableRawPhotoPixelFormatTypes.firstObject.unsignedIntegerValue;
  AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:(OSType)rawFormat];
  settings.flashMode = self.flashMode;
  return settings;
}


/**
 动态壁纸图片导出对象设置
 */
- (AVCapturePhotoSettings *)livePhotoSetting {
  self.photoOutput.livePhotoCaptureEnabled = YES;
  self.photoOutput.livePhotoAutoTrimmingEnabled = YES;
  self.photoOutput.highResolutionCaptureEnabled = YES;
  
  AVCapturePhotoSettings *setting = [[AVCapturePhotoSettings alloc] init];
  if ([setting isHighResolutionPhotoEnabled]) {
    setting.highResolutionPhotoEnabled = _highResolutionEnabled; // 以当前活跃设备和支持的最高分辨率拍照. default = NO
  }
  
  NSURL *writeURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"LivePhotoVideo%ld.mov",(long)setting.uniqueID]]];
  setting.livePhotoMovieFileURL = writeURL;
  
  return setting;
}

- (UIImage *)fixOrientationWith:(UIImage *)image {
  // No-op if the orientation is already correct
  if (image.imageOrientation == UIImageOrientationUp) {
    return image;
  }
  
  // We need to calculate the proper transformation to make the image upright.
  // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
  CGAffineTransform transform = CGAffineTransformIdentity;
  
  switch (image.imageOrientation) {
    case UIImageOrientationDown:
    case UIImageOrientationDownMirrored:
      transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
      transform = CGAffineTransformRotate(transform, M_PI);
      break;
      
    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
      transform = CGAffineTransformTranslate(transform, image.size.width, 0);
      transform = CGAffineTransformRotate(transform, M_PI_2);
      break;
      
    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
      transform = CGAffineTransformTranslate(transform, 0, image.size.height);
      transform = CGAffineTransformRotate(transform, -M_PI_2);
      break;
    default:
      break;
  }
  
  switch (image.imageOrientation) {
    case UIImageOrientationUpMirrored:
    case UIImageOrientationDownMirrored:
      transform = CGAffineTransformTranslate(transform, image.size.width, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;
      
    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRightMirrored:
      transform = CGAffineTransformTranslate(transform, image.size.height, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;
    default:
      break;
  }
  
  // Now we draw the underlying CGImage into a new context, applying the transform
  // calculated above.
  CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                           CGImageGetBitsPerComponent(image.CGImage), 0,
                                           CGImageGetColorSpace(image.CGImage),
                                           CGImageGetBitmapInfo(image.CGImage));
  CGContextConcatCTM(ctx, transform);
  switch (image.imageOrientation) {
    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
      // Grr...
      CGContextDrawImage(ctx, CGRectMake(0,0, image.size.height, image.size.width), image.CGImage);
      break;
      
    default:
      CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
      break;
  }
  
  // And now we just create a new UIImage from the drawing context
  CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
  UIImage *img = [UIImage imageWithCGImage:cgimg];
  CGContextRelease(ctx);
  CGImageRelease(cgimg);
  return img;
}

- (void)checkPhotoLibraryAuthorizationWithCompletitionHandler:(void(^)(BOOL authorized))completionHandler {
  
  switch ([PHPhotoLibrary authorizationStatus]) {
      
    case PHAuthorizationStatusAuthorized: {
      // The user has previously granted access to the photo library.
      completionHandler(YES);
      break;
    }
    case PHAuthorizationStatusNotDetermined: {
      // The user has not yet been presented with the option to grant photo library access so request access.
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        completionHandler((status == PHAuthorizationStatusAuthorized));
        
      }];
      break;
    }
    case PHAuthorizationStatusDenied: {
      // The user has previously denied access.
      completionHandler(NO);
      break;
    }
    case PHAuthorizationStatusRestricted: {
      // The user doesn't have the authority to request access e.g. parental restriction.
      completionHandler(NO);
      break;
    }
      
    default:
      break;
  }
}

- (void)saveLivePhotoToPhotoLibraryWithLivePhotoMovieURL:(NSURL *)livePhotoMovieURL completitionHandler:(void(^)(BOOL success, NSError *error))completionHandler {
  
  [self checkPhotoLibraryAuthorizationWithCompletitionHandler:^(BOOL authorized) {
    
    if (!authorized) {
      NSLog(@"Permission to access photo library denied.");
      completionHandler(NO, nil);
      return;
    }
    
    if (!self.livePhotoData) {
      NSLog(@"Unable to create JPEG data.");
      completionHandler(NO, nil);
      return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
      
      PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
      PHAssetResourceCreationOptions *creationOptions = [[PHAssetResourceCreationOptions alloc] init];
      creationOptions.shouldMoveFile = YES;
      [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:self.livePhotoData options:nil];
      [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:livePhotoMovieURL options:creationOptions];
      
    } completionHandler: completionHandler];
  }];
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  NSLog(@"willBeginCaptureForResolvedSettings");
}

- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  NSLog(@"willCapturePhotoForResolvedSettings");
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  NSLog(@"didCapturePhotoForResolvedSettings");
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error API_AVAILABLE(ios(11.0)) {
  NSData *data = [photo fileDataRepresentation];
  
  if (_takePhotoType == LBCapturePhotoTypeLivePhoto) {
    self.livePhotoData = data;
  } else if (_takePhotoType == LBCapturePhotoTypeRaw) {
    
    NSString *writeFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"raw%@.dng",@(self.photoSettings.uniqueID)]];
 
    [[NSFileManager defaultManager] removeItemAtPath:writeFilePath error:nil];
    //  NSString *filePath = [dir stringByAppendingPathExtension:@"dng"];
    [data writeToFile:writeFilePath atomically:YES];
    
    if (self.capturePhotoBlock) {
      self.capturePhotoBlock(nil);
    }
  } else if (_takePhotoType == LBCapturePhotoTypeNormal) {
    if (self.capturePhotoBlock) {
      UIImage *resultImage = [UIImage imageWithData:data];
      resultImage = [self fixOrientationWith:resultImage];
      self.capturePhotoBlock(resultImage);
    }
  }

}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error API_DEPRECATED("Use -captureOutput:didFinishProcessingPhoto:error: instead.", ios(10.0, 11.0)) {
  
  if (_takePhotoType == LBCapturePhotoTypeLivePhoto) {
    self.livePhotoData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer
                                                                   previewPhotoSampleBuffer:previewPhotoSampleBuffer];
  } else if (_takePhotoType == LBCapturePhotoTypeNormal) {
    if (self.capturePhotoBlock) {
      NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer
                                                                 previewPhotoSampleBuffer:previewPhotoSampleBuffer];
      UIImage *resultImage = [UIImage imageWithData:data];
      resultImage = [self fixOrientationWith:resultImage];
      
      self.capturePhotoBlock(resultImage);
    }
  }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingRawPhotoSampleBuffer:(nullable CMSampleBufferRef)rawSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error API_DEPRECATED("Use -captureOutput:didFinishProcessingPhoto:error: instead.", ios(10.0, 11.0)) {
  // 拍摄raw
  if (_takePhotoType == LBCapturePhotoTypeRaw) {
    NSData *data = [AVCapturePhotoOutput DNGPhotoDataRepresentationForRawSampleBuffer:rawSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
    NSString *writeFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"raw%@.dng",@(self.photoSettings.uniqueID)]];
    
    [[NSFileManager defaultManager] removeItemAtPath:writeFilePath error:nil];
    //  NSString *filePath = [dir stringByAppendingPathExtension:@"dng"];
    [data writeToFile:writeFilePath atomically:YES];
    
    if (self.capturePhotoBlock) {
//      self.capturePhotoBlock(nil, data, [NSURL fileURLWithPath:writeFilePath]);
    }
  }
  
}

// 开始拍摄动态壁纸, 调用一次 显示'LIVE'等回调
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  NSLog(@"[livePhoto] record start");
}

// 动态壁纸拍摄完成, 接收动态照片的拍摄结果
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {
  NSLog(@"[livePhoto] record end");
  
  if (self.capturePhotoBlock) {
//    self.capturePhotoBlock(nil, self.livePhotoData, outputFileURL);
  }

  // livePhoto
  [self saveLivePhotoToPhotoLibraryWithLivePhotoMovieURL:outputFileURL completitionHandler:^(BOOL success, NSError *error) {
    
    if (error) {
      NSLog(@"%@",error.localizedDescription);
    }
  }];
}

// 操作处理完成
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {
//  BOOL success = error ? NO : YES;
//  __weak typeof(self)weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    // 发送通知
    NSLog(@"-------------");
  });
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  if (_recording) {
    [self.bufferWriter writeData:connection
                           video:self.videoConnection
                           audio:self.audioConnection
                          buffer:sampleBuffer];
  }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection API_AVAILABLE(ios(6.0)) {
  
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate

//- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//}

@end
