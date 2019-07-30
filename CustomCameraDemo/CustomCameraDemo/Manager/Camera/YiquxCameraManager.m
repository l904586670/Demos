//
//  YiquxCameraManager.m
//  SnakeScreenByLink
//
//  Created by Rock on 2018/5/10.
//  Copyright © 2018年 Yiqux. All rights reserved.
//

#import "YiquxCameraManager.h"

#import <UIKit/UIKit.h>

#import "YiquxLogic.h"

static const NSString *YQCameraAdjustingExposeureContext = @"camera_expose_id";

// *****************************************************************

@interface YiquxCameraManager () <AVCaptureFileOutputRecordingDelegate,
                                  AVCaptureVideoDataOutputSampleBufferDelegate,
                                  AVCapturePhotoCaptureDelegate>

@property(nonatomic, strong) dispatch_queue_t videoQueue;
@property(nonatomic, strong) AVCaptureSession *captureSession;

@property(nonatomic, strong) AVCaptureDeviceInput *activeVideoInput;

@property(nonatomic, strong) AVCapturePhotoOutput *imageOutput;
@property(nonatomic, strong) AVCapturePhotoSettings *imageOutputSettings;

@property(nonatomic, copy) void(^completeHandler)(UIImage *);

@property(nonatomic, strong) AVCaptureMovieFileOutput *videoFileOutput;

// 视频数据输出, 输出为CMBuffer, 可以用此方法添加实时滤镜之类
@property(nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property(nonatomic, strong) NSURL *outputURL;

@end

@implementation YiquxCameraManager

#pragma mark - Lifecycle

- (instancetype)init {
  if (self = [super init]) {
    _muteMode = NO;
  }
  return self;
}

#pragma mark - Lazy Methods

- (dispatch_queue_t)videoQueue {
  if (!_videoQueue) {
    NSString *label = [[NSBundle mainBundle].bundleIdentifier stringByAppendingString:@".avfoundation.videoQueue"];
    _videoQueue = dispatch_queue_create([label cStringUsingEncoding:NSASCIIStringEncoding], NULL);
  }
  return _videoQueue;
}

- (AVCaptureSession *)captureSession {
  if (!_captureSession) {
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
  }
  return _captureSession;
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

- (AVCapturePhotoOutput *)imageOutput {
  if (!_imageOutput) {
    _imageOutput = [[AVCapturePhotoOutput alloc] init];
    [_imageOutput setPhotoSettingsForSceneMonitoring:self.imageOutputSettings];
  }
  return _imageOutput;
}

- (AVCapturePhotoSettings *)imageOutputSettings {
  NSDictionary *setDic = @{ AVVideoCodecKey : AVVideoCodecJPEG };
  _imageOutputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
  _imageOutputSettings.flashMode = self.flashMode;
  
  return _imageOutputSettings;
}

#pragma mark - Public Methods

- (BOOL)setupSessionWithCameraType:(YQCameraType)cameraType {
  // 设置摄像头
  NSError *error = nil;
  AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

  if (videoInput && !error) {
    if ([self.captureSession canAddInput:videoInput]) {
      [self.captureSession addInput:videoInput];
      self.activeVideoInput = videoInput;
      
      if ([self.captureSession canAddOutput:self.imageOutput]) {
        [self.captureSession addOutput:self.imageOutput];
      }
    }
  } else {
    if (error) {
      YiquxLogFatal(@"Creat video Input error : %@", error.localizedDescription);
    }
    return NO;
  }

  // 设置麦克风
  if (cameraType != YQCameraTypePhoto) {
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if (audioInput && !error) {
      if ([self.captureSession canAddInput:audioInput]) {
        [self.captureSession addInput:audioInput];
      }
      
      // 设置图像输出 为 视频文件输出
      self.videoFileOutput = [[AVCaptureMovieFileOutput alloc] init];
      
      if ([self.captureSession canAddOutput:self.videoFileOutput]) {
        [self.captureSession addOutput:self.videoFileOutput];
      }
    } else {
      if (error) {
        YiquxLogFatal(@"Creat audio Input error : %@", error.localizedDescription);
      }
      return NO;
    }
  }

  return YES;
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

#pragma mark - Camera

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
  AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
  
  for (AVCaptureDevice *device in session.devices) {
    if ([device position] == position) {
      return device;
    }
  }
  
  return nil;
}

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

- (NSUInteger)cameraCount {
  AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];

  return session.devices.count;
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

- (BOOL)canSwitchCameras {
  return self.cameraCount > 1;
}

#pragma mark - Focus & Exposure

- (BOOL)cameraSupportsTapToFocus {
  return [[self acticeCamera] isFocusPointOfInterestSupported];
}

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
      [self mediaLockConfigurationFailedWithError:error];
    }
  }
}

// [1, activeFormat.videoMaxZoomFactor]
- (void)videoZoomWithFactor:(CGFloat)factor {
  AVCaptureDevice *device = [self acticeCamera];
  if (factor < 1.0 || factor > device.activeFormat.videoMaxZoomFactor) {
    YiquxLogFatal(@"Video zoom factor out [1, activeFormat.videoMaxZoomFactor]");
  }
  
  factor = MAX(1, factor);
  factor = MIN(factor, device.activeFormat.videoMaxZoomFactor);

  NSError *error = nil;
  if ([device lockForConfiguration:&error]) {
    device.videoZoomFactor = factor;
    [device unlockForConfiguration];
  } else {
    [self mediaLockConfigurationFailedWithError:error];
  }
}

- (BOOL)cameraSupportsTapToExpose {
  return [[self acticeCamera] isExposurePointOfInterestSupported];
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
                    context:&YQCameraAdjustingExposeureContext];
      }
      
      [device unlockForConfiguration];
    } else {
      [self mediaLockConfigurationFailedWithError:error];
    }
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if (context == &YQCameraAdjustingExposeureContext) {
    AVCaptureDevice *device = (AVCaptureDevice *)object;

    if (!device.isAdjustingExposure &&
        [device isExposureModeSupported:AVCaptureExposureModeLocked]) {
      [object removeObserver:self
                  forKeyPath:@"adjustingExposure"
                     context:&YQCameraAdjustingExposeureContext];

      dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
          device.exposureMode = AVCaptureExposureModeLocked;
          [device unlockForConfiguration];
        } else {
          [self mediaLockConfigurationFailedWithError:error];
        }
      });
    }
  } else {
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
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
  } else {
    [self mediaLockConfigurationFailedWithError:error];
  }
}

#pragma mark - Flash & Torch

- (BOOL)cameraHasFlash {
  return [[self acticeCamera] hasFlash];
}

- (BOOL)cameraHasTorch {
  return [[self acticeCamera] hasTorch];
}

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
      [self mediaLockConfigurationFailedWithError:error];
    }
  }
}

- (void)captureStillImage:(void(^)(UIImage *stillImage))completeHandler {
  self.completeHandler = completeHandler;
  
  [self.imageOutput capturePhotoWithSettings:self.imageOutputSettings delegate:self];
}

- (AVCaptureVideoOrientation)currentVideoOrientation {
  UIDeviceOrientation sataus = [UIDevice currentDevice].orientation;
  switch (sataus) {
    case UIDeviceOrientationPortrait:
      return AVCaptureVideoOrientationPortrait;
    case UIDeviceOrientationLandscapeRight:
      return AVCaptureVideoOrientationLandscapeLeft;
    case UIDeviceOrientationLandscapeLeft:
      return AVCaptureVideoOrientationLandscapeRight;
    default:
      return AVCaptureVideoOrientationPortraitUpsideDown;
  }
}

#pragma mark - Video Methods

- (BOOL)isRecording {
  return self.videoFileOutput.isRecording;
}

- (void)startRecording {
  if ([self isRecording]) {
    return;
  }
  
  AVCaptureConnection *videoConnection = [self.videoFileOutput connectionWithMediaType:AVMediaTypeVideo];
  
  // 视频方向
  if ([videoConnection isVideoOrientationSupported]) {
    videoConnection.videoOrientation = [self currentVideoOrientation];
  }
  
  // 摄像头镜像
  AVCaptureDevicePosition currentPosition = [self acticeCamera].position;
  videoConnection.videoMirrored = ((AVCaptureDevicePositionUnspecified == currentPosition) ||
                                   (AVCaptureDevicePositionFront == currentPosition));
  
  // 视频防抖
  if ([videoConnection isVideoStabilizationSupported]) {
    videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
//    videoConnection.enablesVideoStabilizationWhenAvailable = YES;
  }
  
  AVCaptureDevice *device = [self acticeCamera];
  
  // 视频平稳对焦
  if (device.isSmoothAutoFocusSupported) {
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
      device.smoothAutoFocusEnabled = YES;
      [device unlockForConfiguration];
    } else {
      [self mediaLockConfigurationFailedWithError:error];
    }
  }
  
  self.outputURL = [self uniqueURL];
  
  [self.videoFileOutput startRecordingToOutputFileURL:self.outputURL
                                    recordingDelegate:self];
}

- (void)stopRecording {
  if ([self isRecording]) {
    [self.videoFileOutput stopRecording];
  }
}

- (NSURL *)uniqueURL {
  NSString *folderName = @"videoTempDir";
  NSString *dirPath = [self temporaryDirectoryWithTemplateString:folderName];

  if (dirPath) {
    NSString *filePath = [dirPath stringByAppendingPathComponent:@"temp_movie.mov"];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    return [NSURL fileURLWithPath:filePath];
  } else {
    YiquxLogFatal(@"Creat video folder Error : %@", folderName);
    return nil;
  }
}

#pragma mark - Private Methods

- (void)mediaCaptureFailedWithError:(NSError *)error {
  if ([self.delegate respondsToSelector:@selector(mediaCaptureFailedWithError:)]) {
    [self.delegate mediaCaptureFailedWithError:error];
  }
}

- (void)mediaCaptureVideoOutputFileUrl:(NSURL *)outputUrl {
  if ([self.delegate respondsToSelector:@selector(mediaCaptureVideoOutputFileUrl:)]) {
    [self.delegate mediaCaptureVideoOutputFileUrl:outputUrl];
  }
}

- (void)mediaLockConfigurationFailedWithError:(NSError *)error {
  if ([self.delegate respondsToSelector:@selector(mediaLockConfigurationFailedWithError:)]) {
    [self.delegate mediaLockConfigurationFailedWithError:error];
  }
}

- (NSString *)temporaryDirectoryWithTemplateString:(NSString *)templateString {
  NSString *mkdTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:templateString];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  BOOL isDir = NO;
  BOOL existed = [fileManager fileExistsAtPath:mkdTemplate isDirectory:&isDir];
  
  if (isDir || !existed) {
    [fileManager createDirectoryAtPath:mkdTemplate
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
  }

  return mkdTemplate;
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)output
  didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray<AVCaptureConnection *> *)connections
                error:(nullable NSError *)error {
  if (error) {
    [self mediaCaptureFailedWithError:error];
  } else {
    [self mediaCaptureVideoOutputFileUrl:outputFileURL];
  }
  
  self.outputURL = nil;
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
}

- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error {
  if (NULL == photoSampleBuffer || error) {
    YiquxLogError(@"Capture photo error: %@", error);
    
    if (self.completeHandler) {
      self.completeHandler(nil);
    }
    
    return;
  }
  
  NSData *imageData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
  
  UIImage *image = [[UIImage imageWithData:imageData] fixOrientation];

  if ([self acticeCamera].position == AVCaptureDevicePositionFront) {
    image = [image flipHorizontal];
  }
  
  if (CGSizeEqualToSize(_previewSize, CGSizeZero)) {
    if (self.completeHandler) {
      self.completeHandler(image);
    }
    
    return;
  }
  
  CGRect cropRect = [GeometryMath makeRectWithAspectRatioInsideRect:_previewSize boundingRect:CGRectMake(0, 0, image.size.width, image.size.height)];
  UIImage *croppedImage = [image croppedImage:cropRect];
  
  if (self.completeHandler) {
    self.completeHandler(croppedImage);
  }
}

@end
