//
//  LBCameraManager.m
//  CustomCameraDemo
//
//  Created by Rock on 2019/8/12.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "LBCameraManager.h"

static const NSString *LBCameraAdjustingExposeureContext = @"LBCameraAdjustingExposeureContext";

@interface LBCameraManager () <AVCaptureVideoDataOutputSampleBufferDelegate,
                               AVCapturePhotoCaptureDelegate>

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
@property (nonatomic, copy) CapturePhotoBlock capturePhotoBlock;

@end

@implementation LBCameraManager

#pragma mark - Lifecycle

- (instancetype)init {
  if (self = [super init]) {

    _torchMode = AVCaptureTorchModeAuto;
    _flashMode = AVCaptureFlashModeOff;

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

    // 默认给一个高配置
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
      _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    } else if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
      _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    } else {
      _captureSession.sessionPreset = AVCaptureSessionPresetLow;
    }

  }
  return _captureSession;
}

#pragma mark - Public Methods

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

//- (BOOL)isRecording {
//  return self.videoFileOutput.isRecording;
//}


- (void)capturePhoto:(CapturePhotoBlock)completeHandler {
  self.capturePhotoBlock = completeHandler;


  
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


+ (AVCaptureDevice *)dualCameraDevice API_AVAILABLE(ios(10.2)) {
  AVCaptureDevice *device = nil;
  if (@available(iOS 10.2, *)) {
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDualCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    device = [discoverySession.devices firstObject];
  }

  // 不支持后置双摄给一个默认的广角摄像头
  if (!device) {
    device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
  }

  return device;
}

#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  NSLog(@"willBeginCaptureForResolvedSettings");
}

- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  NSLog(@"willCapturePhotoForResolvedSettings");
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {

}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error API_AVAILABLE(ios(11.0)) {

  NSData *data = [photo fileDataRepresentation];

  NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"测试.dng"];
  [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
  //  NSString *filePath = [dir stringByAppendingPathExtension:@"dng"];
  [data writeToFile:outputPath atomically:YES];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error API_DEPRECATED("Use -captureOutput:didFinishProcessingPhoto:error: instead.", ios(10.0, 11.0)) {

}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingRawPhotoSampleBuffer:(nullable CMSampleBufferRef)rawSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error API_DEPRECATED("Use -captureOutput:didFinishProcessingPhoto:error: instead.", ios(10.0, 11.0)) {
  // 拍摄raw
  NSData *data = [AVCapturePhotoOutput DNGPhotoDataRepresentationForRawSampleBuffer:rawSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
  NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"测试.dng"];
  //  NSString *filePath = [dir stringByAppendingPathExtension:@"dng"];
  [data writeToFile:outputPath atomically:YES];
  // do something...

}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {

}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {

}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {

}


@end
