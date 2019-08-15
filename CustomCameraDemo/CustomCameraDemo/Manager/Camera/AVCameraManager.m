//
//  AVCameraManager.m
//  CustomCameraDemo
//
//  Created by User on 2019/8/15.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "AVCameraManager.h"

#import "DHVideoBufferWriter.h"
#import "DHCameraHelper.h"

static const NSString *CameraAdjustingExposeureContext = @"CameraAdjustingExposeureContext";

@interface AVCameraManager () <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic,strong) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;
@property (nonatomic, strong) AVCaptureDeviceInput *activeVideoInput;


// 视频数据输出, 输出为CMBuffer, 可以用此方法添加实时滤镜之类
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

@property (nonatomic, assign) BOOL recording;

@property (nonatomic, strong) DHVideoBufferWriter *bufferWriter;


/***  图片相关  ***/

// 图片的输出会话
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) NSData *photoData;
@property (nonatomic, copy) CapturePhotoResult capturePhotoBlock;

@end


@implementation AVCameraManager

- (instancetype)init {
  self = [super init];
  if (self) {
    
    self.session = [[AVCaptureSession alloc] init];
    self.videoDeviceDiscoverySession = [DHCameraHelper deviceDiscoverySessionWith:AVCaptureDevicePositionUnspecified];
    [self sessionQueue];
  
    [self configureSession];
  }
  return self;
}

#pragma mark - Lazy Methods

- (dispatch_queue_t)sessionQueue {
  if (!_sessionQueue) {
    NSString *label = [[NSBundle mainBundle].bundleIdentifier stringByAppendingString:@".avfoundation.videoQueue"];
    _sessionQueue = dispatch_queue_create([label cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
  }
  return _sessionQueue;
}

- (AVCaptureVideoDataOutput *)videoDataOutput {
  if (!_videoDataOutput) {
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    _videoDataOutput.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    
    [_videoDataOutput setSampleBufferDelegate:self queue:self.sessionQueue];
  }
  return _videoDataOutput;
}

- (AVCaptureAudioDataOutput *)audioDataOutput {
  if (!_audioDataOutput) {
    _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioDataOutput setSampleBufferDelegate:self queue:self.sessionQueue];
  }
  return _audioDataOutput;
}

- (DHVideoBufferWriter *)bufferWriter {
  if (!_bufferWriter) {
    _bufferWriter = [[DHVideoBufferWriter alloc] init];
  }
  return _bufferWriter;
}

#pragma mark - Public Methods

- (void)switchCamera {
  dispatch_async(self.sessionQueue, ^{
    AVCaptureDevice *currentVideoDevice = self.activeVideoInput.device;
    AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
    
    AVCaptureDevicePosition preferredPosition;
    AVCaptureDeviceType preferredDeviceType;
    
    switch (currentPosition) {
      case AVCaptureDevicePositionUnspecified:
      case AVCaptureDevicePositionFront:
        preferredPosition = AVCaptureDevicePositionBack;
        if (@available(iOS 10.2, *)) {
          preferredDeviceType = AVCaptureDeviceTypeBuiltInDualCamera;
        } else {
          preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
          // Fallback on earlier versions
        }
        break;
      case AVCaptureDevicePositionBack:
        preferredPosition = AVCaptureDevicePositionFront;
        if (@available(iOS 11.1, *)) {
          preferredDeviceType = AVCaptureDeviceTypeBuiltInTrueDepthCamera;
        } else {
          preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
          // Fallback on earlier versions
        };
        break;
    }
    
    NSArray <AVCaptureDevice* >*devices = self.videoDeviceDiscoverySession.devices;
    AVCaptureDevice *newVideoDevice = nil;
    
    // First, look for a device with both the preferred position and device type.
    for (AVCaptureDevice *device in devices) {
      if (device.position == preferredPosition && [device.deviceType isEqualToString:preferredDeviceType]) {
        newVideoDevice = device;
        break;
      }
    }
    
    // Otherwise, look for a device with only the preferred position.
    if (!newVideoDevice) {
      for (AVCaptureDevice* device in devices) {
        if (device.position == preferredPosition) {
          newVideoDevice = device;
          break;
        }
      }
    }
    
    if (newVideoDevice) {
      AVCaptureDeviceInput* videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];
      
      [self.session beginConfiguration];
      
      // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
      [self.session removeInput:self.activeVideoInput];
      
      if ([self.session canAddInput:videoDeviceInput]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
      
        [self.session addInput:videoDeviceInput];
        self.activeVideoInput = videoDeviceInput;
      } else {
        [self.session addInput:self.activeVideoInput];
      }
      
      AVCaptureConnection *videoDataOutputConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
      if (videoDataOutputConnection.isVideoStabilizationSupported) {
        videoDataOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
      }
      
      /*
       Set Live Photo capture and depth data delivery if it is supported. When changing cameras, the
       `livePhotoCaptureEnabled` and `depthDataDeliveryEnabled` properties of the AVCapturePhotoOutput gets set to NO when
       a video device is disconnected from the session. After the new video device is
       added to the session, re-enable Live Photo capture and depth data delivery if they are supported.
       */
      self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
      self.photoOutput.livePhotoCaptureEnabled = NO;
      if (@available(iOS 11.0, *)) {
        self.photoOutput.depthDataDeliveryEnabled = self.photoOutput.depthDataDeliverySupported;
      }
      if (@available(iOS 12.0, *)) {
        self.photoOutput.portraitEffectsMatteDeliveryEnabled = self.photoOutput.portraitEffectsMatteDeliverySupported;
      }
      
      [self.session commitConfiguration];
    }
  });
}

- (void)changeCaptureMode:(AVCaptureMode)captureMode {
  if (captureMode == AVCaptureModePhoto) {
    dispatch_async(self.sessionQueue, ^{
      /*
       Remove the AVCaptureMovieFileOutput from the session because Live Photo
       capture is not supported when an AVCaptureMovieFileOutput is connected to the session.
       */
      [self.session beginConfiguration];
      [self.session removeOutput:self.videoDataOutput];
      [self.session removeOutput:self.audioDataOutput];
      self.session.sessionPreset = AVCaptureSessionPresetPhoto;
      
      self.videoDataOutput = nil;
      
//      if (self.photoOutput.livePhotoCaptureSupported) {
//        self.photoOutput.livePhotoCaptureEnabled = NO;
//      }
      
      if (@available(iOS 11.0, *)) {
        if (self.photoOutput.depthDataDeliverySupported) {
          self.photoOutput.depthDataDeliveryEnabled = YES;
        }
      }
      
      if (@available(iOS 12.0, *)) {
        if (self.photoOutput.portraitEffectsMatteDeliverySupported) {
          self.photoOutput.portraitEffectsMatteDeliveryEnabled = YES;
        }
      }
      
      [self.session commitConfiguration];
    });
  } else {
 
    dispatch_async(self.sessionQueue, ^{
      
      if ([self.session canAddOutput:self.videoDataOutput]) {
        [self.session beginConfiguration];
        [self.session addOutput:self.videoDataOutput];
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
        AVCaptureConnection *connection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoStabilizationSupported) {
          connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        [self.session commitConfiguration];
      }
      
      if ([self.session canAddOutput:self.audioDataOutput]) {
        [self.session beginConfiguration];
        [self.session addOutput:self.audioDataOutput];
        [self.session commitConfiguration];
      }
    });
  }
}

- (void)focusAtPoint:(CGPoint)point {
  AVCaptureDevice *device = self.activeVideoInput.device;
  
  if (device.isFocusPointOfInterestSupported &&
      [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
      device.focusPointOfInterest = point;
      device.focusMode = AVCaptureFocusModeAutoFocus;
      [device unlockForConfiguration];
    }
  }
}

- (void)exposeAtPoint:(CGPoint)point {
  AVCaptureDevice *device = self.activeVideoInput.device;
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
                    context:&CameraAdjustingExposeureContext];
      }
      
      [device unlockForConfiguration];
    }
  }
}
- (void)resetFocusAndExposureModes {
  AVCaptureDevice *device = self.activeVideoInput.device;;
  
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
  AVCaptureDevice *device = self.activeVideoInput.device;;
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

- (void)capturePhoto:(CapturePhotoResult)completeHandler {
  self.capturePhotoBlock = completeHandler;
  
  AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.bufferWriter.videoOrientation;
  
  dispatch_async(self.sessionQueue, ^{
    
    // Update the photo output's connection to match the video orientation of the video preview layer.
    AVCaptureConnection *photoOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
    photoOutputConnection.videoOrientation = videoPreviewLayerVideoOrientation;
    
    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
    // Capture HEIF photos when supported, with the flash set to enable auto- and high-resolution photos.
    if (@available(iOS 11.0, *)) {
      if ([self.photoOutput.availablePhotoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
        photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{ AVVideoCodecKey : AVVideoCodecTypeHEVC }];
      }
    }
    
    if (self.activeVideoInput.device.isFlashAvailable) {
      photoSettings.flashMode = self.flashMode;
    }
    photoSettings.highResolutionPhotoEnabled = YES;
    if (photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0) {
      photoSettings.previewPhotoFormat = @{ (NSString*)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject };
    }
    
    [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
  });
}

- (void)startRecording {
  self.bufferWriter.devicePosition = self.activeVideoInput.device.position;
  
  if (_recording) {
    return;
  }
  
  AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.bufferWriter.videoOrientation;
  
  dispatch_async(self.sessionQueue, ^{
    AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoOrientation = videoPreviewLayerVideoOrientation;
    AVCaptureDevice *device = self.activeVideoInput.device;
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
      }
    }
    
    [self.bufferWriter startWrite];
    
    self->_recording = YES;
  });
}

- (void)stopRecording {
  _recording = NO;
  dispatch_async(self.sessionQueue, ^{
    [self.bufferWriter stopWrite:^(NSURL * _Nullable outputUrl, NSError * _Nullable error) {
      
    }];
  });
}

- (BOOL)isRecording {
  return _recording;
}

#pragma mark - Private Methods

// Call this on the session queue.
- (void)configureSession {
  NSError *error = nil;
  [self.session beginConfiguration];
  
  /*
   We do not create an AVCaptureMovieFileOutput when setting up the session because
   Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
   */
  // 默认先给一个high 如果要导出动态壁纸或者RAW类型的图片. sessionPreset 要设置为Photo 类型
  if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
  } else if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
    self.session.sessionPreset = AVCaptureSessionPreset1280x720;
  }
  
  // Add video input.
  
  // Choose the back dual camera if available, otherwise default to a wide angle camera.
  AVCaptureDevice *videoDevice = [DHCameraHelper defaultCameraDevice];
  
  AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
  if (!videoDeviceInput) {
    NSLog(@"Could not create video device input: %@", error);
    [self.session commitConfiguration];
    return;
  }
  
  if ([self.session canAddInput:videoDeviceInput]) {
    [self.session addInput:videoDeviceInput];
    self.activeVideoInput = videoDeviceInput;
    // 设置预览界面的视频方向信息
  } else {
    NSLog(@"Could not add video device input to the session");
    [self.session commitConfiguration];
    return;
  }
  
  // Add audio input.
  AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
  if (!audioDeviceInput) {
    NSLog(@"Could not create audio device input: %@", error);
  }
  if ([self.session canAddInput:audioDeviceInput]) {
    [self.session addInput:audioDeviceInput];
  } else {
    NSLog(@"Could not add audio device input to the session");
  }
  
  // Add photo output.
  AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
  if ([self.session canAddOutput:photoOutput]) {
    [self.session addOutput:photoOutput];
    self.photoOutput = photoOutput;
    // 高帧率模式
    self.photoOutput.highResolutionCaptureEnabled = YES;
    // 能否导出为动态壁纸
//    self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
    self.photoOutput.livePhotoCaptureEnabled = NO;
    // 深度数据
    if (@available(iOS 11.0, *)) {
      self.photoOutput.depthDataDeliveryEnabled = self.photoOutput.depthDataDeliverySupported;
    }
    if (@available(iOS 12.0, *)) {
      self.photoOutput.portraitEffectsMatteDeliveryEnabled = self.photoOutput.portraitEffectsMatteDeliverySupported;
    }

  } else {
    NSLog(@"Could not add photo output to the session");
    [self.session commitConfiguration];
    return;
  }
  
  // 添加video output
  if ([self.session canAddOutput:self.videoDataOutput]) {
    [self.session addOutput:self.videoDataOutput];
  }
  if ([self.session canAddOutput:self.audioDataOutput]) {
    [self.session addOutput:self.audioDataOutput];
  }

  [self.session commitConfiguration];
}

#pragma mark - KVO Action

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if (context == &CameraAdjustingExposeureContext) {
    AVCaptureDevice *device = (AVCaptureDevice *)object;
    
    if (!device.isAdjustingExposure &&
        [device isExposureModeSupported:AVCaptureExposureModeLocked]) {
      [object removeObserver:self
                  forKeyPath:@"adjustingExposure"
                     context:&CameraAdjustingExposeureContext];
      
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

#pragma mark - AVCapturePhotoCaptureDelegate

// 点击拍照后第一个调用此方法, 验证设置
- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  if ( ( resolvedSettings.livePhotoMovieDimensions.width > 0 ) && ( resolvedSettings.livePhotoMovieDimensions.height > 0 ) ) {
    // 显示 livePhoto Live icon
  }
}

// 点击拍照后第二个调用此方法, 发出快门声后调用, livePhoto 时不会发出快门声
- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  if ([self.photoDelegate respondsToSelector:@selector(CameraWillCapturePhotoAnimation)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.photoDelegate CameraWillCapturePhotoAnimation];
    });
  }

  if ([self.photoDelegate respondsToSelector:@selector(CameraPhotoProcessingStart)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.photoDelegate CameraPhotoProcessingStart];
    });
  }
  
  // Show spinner if processing time exceeds 1 second
//  CMTime onesec = CMTimeMake(1, 1);
//  if ( CMTimeCompare(self.maxPhotoProcessingTime, onesec) > 0 ) {
//    self.photoProcessingHandler( YES );
//  }
}

// 第三个响应此方法
- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  
}

// 第四个调用此方法, 开始拍摄动态壁纸完成, 做一些隐藏'LIVE'等回调
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
 
}

// 第五个调用此方法, livePhoto mov文件写入磁盘后调用
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {
  if (error) {
    NSLog( @"Error processing Live Photo companion movie: %@", error );
    return;
  }
  // 在此位置 获取livePhoto 文件位置
}

// 照片处理完成后回调 IOS 10.0 ~ 11.0
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error {
  
  self.photoData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer
                                                               previewPhotoSampleBuffer:previewPhotoSampleBuffer];
  
  if ([self.photoDelegate respondsToSelector:@selector(CameraPhotoProcessingEnd:error:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.photoDelegate CameraPhotoProcessingEnd:self.photoData error:error];
    });
  }
  if (self.capturePhotoBlock) {
    self.capturePhotoBlock( [self fixOrientationWith:[UIImage imageWithData:self.photoData]], self.photoData);
  }

}

// 照片处理完成后回调 IOS 11.0~
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error  API_AVAILABLE(ios(11.0)) {
  
  self.photoData = [photo fileDataRepresentation];
  
  if ([self.photoDelegate respondsToSelector:@selector(CameraPhotoProcessingEnd:error:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.photoDelegate CameraPhotoProcessingEnd:self.photoData error:error];
    });
  }
  
  if (self.capturePhotoBlock) {
    self.capturePhotoBlock([self fixOrientationWith:[UIImage imageWithData:self.photoData]], self.photoData);
  }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingRawPhotoSampleBuffer:(nullable CMSampleBufferRef)rawSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error {
  //  NSData *data = [AVCapturePhotoOutput DNGPhotoDataRepresentationForRawSampleBuffer:rawSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {
  
  if ([self.photoDelegate respondsToSelector:@selector(CameraFinishCaptureWithError:)]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.photoDelegate CameraFinishCaptureWithError:error];
    });
  }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  if (_recording) {
    @autoreleasepool {
      if (connection == [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo]) {
        [self.bufferWriter addDataBuffer:sampleBuffer mediaType:AVMediaTypeVideo];
      } else if (connection == [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio])  {
      [self.bufferWriter addDataBuffer:sampleBuffer mediaType:AVMediaTypeAudio];
      }
    }
  }
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection API_AVAILABLE(ios(6.0)) {
  
}

#pragma mark - Other

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

@end



