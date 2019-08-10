//
//  DHCameraManager.m
//  CustomCameraDemo
//
//  Created by User on 2019/8/1.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "DHCameraManager.h"

#import "DHCameraHelper.h"

@interface DHCameraManager () <AVCapturePhotoCaptureDelegate>

@property(nonatomic, strong) dispatch_queue_t videoQueue;
@property(nonatomic, strong) AVCaptureSession *captureSession;

// 图片的输出会话
@property(nonatomic, strong) AVCapturePhotoOutput *photoOutput;
// 图片的输出设置
@property(nonatomic, strong) AVCapturePhotoSettings *photoSettings;

@end

@implementation DHCameraManager

#pragma mark - Life Cycle Methods

- (instancetype)init {
  if (self = [super init]) {
    _photoType = DHPhotoTypeNormal;
    _photoOutput = [[AVCapturePhotoOutput alloc] init];
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
    _captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
  }
  return _captureSession;
}

- (AVCapturePhotoSettings *)imageOutputSettings {
  NSUInteger rawFormat = self.photoOutput.availableRawPhotoPixelFormatTypes.firstObject.unsignedIntegerValue;
  self.photoSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:(OSType)rawFormat];
  
//  if (_photoType == DHPhotoTypeNormal) {
//    NSDictionary *setDic = @{ AVVideoCodecKey : AVVideoCodecJPEG };
//    _imageOutputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
//    //  _imageOutputSettings.flashMode = self.flashMode; // 设置在拍照时是否触发闪光灯
//    if (@available(iOS 12.0, *)) {
//      // 闪光灯时自动防红眼
//      _imageOutputSettings.autoRedEyeReductionEnabled = YES;
//    }
//    //  _imageOutputSettings.highResolutionPhotoEnabled = YES; // 以当前活跃设备和支持的最高分辨率拍照. default = NO
//    //  _imageOutputSettings.cameraCalibrationDataDeliveryEnabled = NO;
//    _imageOutputSettings.autoStillImageStabilizationEnabled = YES; // 自动图像稳定
//    if (@available(iOS 10.2, *)) {
//      if ([_imageOutputSettings isAutoDualCameraFusionEnabled]) {
//        // 自动组合双摄像头设备数据
//        _imageOutputSettings.autoDualCameraFusionEnabled = YES;
//      }
//    }
//  } else if (_photoType == DHPhotoTypeRaw) {
//
//  } else if (_photoType == DHPhotoTypeLivePhoto) {
//    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"livePhoto.jpg"];
//    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
//    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
//    _imageOutputSettings.livePhotoMovieFileURL = fileUrl;
//  }
//
//  NSDictionary *setDic = @{ AVVideoCodecKey : AVVideoCodecJPEG };
//  _imageOutputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
////  _imageOutputSettings.flashMode = self.flashMode; // 设置在拍照时是否触发闪光灯
//  if (@available(iOS 12.0, *)) {
//    // 闪光灯时自动防红眼
//    _imageOutputSettings.autoRedEyeReductionEnabled = YES;
//  }
////  _imageOutputSettings.highResolutionPhotoEnabled = YES; // 以当前活跃设备和支持的最高分辨率拍照. default = NO
////  _imageOutputSettings.cameraCalibrationDataDeliveryEnabled = NO;
//  _imageOutputSettings.autoStillImageStabilizationEnabled = YES; // 自动图像稳定
//  if (@available(iOS 10.2, *)) {
//    if ([_imageOutputSettings isAutoDualCameraFusionEnabled]) {
//      // 自动组合双摄像头设备数据
//      _imageOutputSettings.autoDualCameraFusionEnabled = YES;
//    }
//  }
  return _photoSettings;
}

#pragma mark - Setter Methods

- (void)setPhotoType:(DHPhotoType)photoType {
  _photoType = photoType;
  
  if (_photoType == DHPhotoTypeLivePhoto) {
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
      [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    }
  }
}


#pragma mark - Public Methods

- (void)setupSession {
  // 设置摄像头
  NSError *error = nil;
  
  AVCaptureDevice *videoDevice = [DHCameraHelper dualCameraDevice];
  AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
  if (error) {
    NSAssert(NO, @"add device input error : %@", error.description);
  }
  
  if ([self.captureSession canAddInput:videoInput]) {
    [self.captureSession addInput:videoInput];
  }
  
  if ([self.captureSession canAddOutput:self.photoOutput]) {
    [self.captureSession addOutput:self.photoOutput];
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

- (void)captureStillImage {
 
  NSArray <NSNumber *>*formateTypes = self.photoOutput.availableRawPhotoPixelFormatTypes;
  NSUInteger rawFormat = formateTypes.firstObject.unsignedIntegerValue;
  
  // 压缩格式类型
  NSArray <AVVideoCodecType>* codecTypes = self.photoOutput.availablePhotoCodecTypes;
  
  
  
//  self.photoSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:(OSType)rawFormat rawFileType:AVFileTypeDNG processedFormat:<#(nullable NSDictionary<NSString *,id> *)#> processedFileType:<#(nullable AVFileType)#>];
//  self.photoSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:(OSType)rawFormat];
//   预览图支持格式
//    NSArray <NSNumber *>*previewFormateTypes = self.photoOutput.availablePreviewPhotoPixelFormatTypes;
//    NSDictionary *previewSetting = @{ kCVPixelBufferPixelFormatTypeKey : };
  
  self.photoSettings = [AVCapturePhotoSettings photoSettings];
  

  
  // 光学防抖. raw 时关闭
//  self.photoSettings.autoStillImageStabilizationEnabled = YES;
//  // 高分辨率捕捉图像
////  self.photoSettings.highResolutionPhotoEnabled = YES;
//  if (@available(iOS 11.0, *)) {
//    self.photoSettings.dualCameraDualPhotoDeliveryEnabled = YES;
//  }
//  if (@available(iOS 10.2, *)) {
//    self.photoSettings.autoDualCameraFusionEnabled = YES;
//  }
  
//  self.photoSettings.flashMode = AVCaptureFlashModeOff;
  
  
  
  [self.photoOutput capturePhotoWithSettings:self.photoSettings delegate:self];
}


#pragma mark - Private Methods


#pragma mark - AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  NSLog(@"willBeginCaptureForResolvedSettings");
}

/*!
 @method captureOutput:willCapturePhotoForResolvedSettings:
 @abstract
 A callback fired just as the photo is being taken.
 
 @param output
 The calling instance of AVCapturePhotoOutput.
 @param resolvedSettings
 An instance of AVCaptureResolvedPhotoSettings indicating which capture features have been selected.
 
 @discussion
 The timing of this callback is analogous to AVCaptureStillImageOutput's capturingStillImage property changing from NO to YES. The callback is delivered right after the shutter sound is heard (note that shutter sounds are suppressed when Live Photos are being captured).
 */
- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  NSLog(@"willCapturePhotoForResolvedSettings");
}

/*!
 @method captureOutput:didCapturePhotoForResolvedSettings:
 @abstract
 A callback fired just after the photo is taken.
 
 @param output
 The calling instance of AVCapturePhotoOutput.
 @param resolvedSettings
 An instance of AVCaptureResolvedPhotoSettings indicating which capture features have been selected.
 
 @discussion
 The timing of this callback is analogous to AVCaptureStillImageOutput's capturingStillImage property changing from YES to NO.
 */
- (void)captureOutput:(AVCapturePhotoOutput *)output didCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  
}

/*!
 @method captureOutput:didFinishProcessingPhoto:error:
 @abstract
 A callback fired when photos are ready to be delivered to you (RAW or processed).
 
 @param output
 The calling instance of AVCapturePhotoOutput.
 @param photo
 An instance of AVCapturePhoto.
 @param error
 An error indicating what went wrong. If the photo was processed successfully, nil is returned.
 
 @discussion
 This callback fires resolvedSettings.expectedPhotoCount number of times for a given capture request. Note that the photo parameter is always non nil, even if an error is returned. The delivered AVCapturePhoto's rawPhoto property can be queried to know if it's a RAW image or processed image.
 */
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error API_AVAILABLE(ios(11.0)) {
  
  NSData *data = [photo fileDataRepresentation];
  
  NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"测试.dng"];
  [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
  //  NSString *filePath = [dir stringByAppendingPathExtension:@"dng"];
  [data writeToFile:outputPath atomically:YES];
}

/*!
 @method captureOutput:didFinishProcessingPhotoSampleBuffer:previewPhotoSampleBuffer:resolvedSettings:bracketSettings:error:
 @abstract
 A callback fired when the primary processed photo or photos are done.
 
 @param output
 The calling instance of AVCapturePhotoOutput.
 @param photoSampleBuffer
 A CMSampleBuffer containing an uncompressed pixel buffer or compressed data, along with timing information and metadata. May be nil if there was an error.
 @param previewPhotoSampleBuffer
 An optional CMSampleBuffer containing an uncompressed, down-scaled preview pixel buffer. Note that the preview sample buffer contains no metadata. Refer to the photoSampleBuffer for metadata (e.g., the orientation). May be nil.
 @param resolvedSettings
 An instance of AVCaptureResolvedPhotoSettings indicating which capture features have been selected.
 @param bracketSettings
 If this image is being delivered as part of a bracketed capture, the bracketSettings corresponding to this image. Otherwise nil.
 @param error
 An error indicating what went wrong if photoSampleBuffer is nil.
 
 @discussion
 If you've requested a single processed image (uncompressed or compressed) capture, the photo is delivered here. If you've requested a bracketed capture, this callback is fired bracketedSettings.count times (once for each photo in the bracket).
 */
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error API_DEPRECATED("Use -captureOutput:didFinishProcessingPhoto:error: instead.", ios(10.0, 11.0)) {
  
}

/*!
 @method captureOutput:didFinishProcessingRawPhotoSampleBuffer:previewPhotoSampleBuffer:resolvedSettings:bracketSettings:error:
 @abstract
 A callback fired when the RAW photo or photos are done.
 
 @param output
 The calling instance of AVCapturePhotoOutput.
 @param rawSampleBuffer
 A CMSampleBuffer containing Bayer RAW pixel data, along with timing information and metadata. May be nil if there was an error.
 @param previewPhotoSampleBuffer
 An optional CMSampleBuffer containing an uncompressed, down-scaled preview pixel buffer. Note that the preview sample buffer contains no metadata. Refer to the rawSampleBuffer for metadata (e.g., the orientation). May be nil.
 @param resolvedSettings
 An instance of AVCaptureResolvedPhotoSettings indicating which capture features have been selected.
 @param bracketSettings
 If this image is being delivered as part of a bracketed capture, the bracketSettings corresponding to this image. Otherwise nil.
 @param error
 An error indicating what went wrong if rawSampleBuffer is nil.
 
 @discussion
 Single RAW image and bracketed RAW photos are delivered here. If you've requested a RAW bracketed capture, this callback is fired bracketedSettings.count times (once for each photo in the bracket).
 */
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingRawPhotoSampleBuffer:(nullable CMSampleBufferRef)rawSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error API_DEPRECATED("Use -captureOutput:didFinishProcessingPhoto:error: instead.", ios(10.0, 11.0)) {
  // 拍摄raw
  NSData *data = [AVCapturePhotoOutput DNGPhotoDataRepresentationForRawSampleBuffer:rawSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
  NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"测试.dng"];
//  NSString *filePath = [dir stringByAppendingPathExtension:@"dng"];
  [data writeToFile:outputPath atomically:YES];
  // do something...
  
}

/*!
 @method captureOutput:didFinishRecordingLivePhotoMovieForEventualFileAtURL:resolvedSettings:
 @abstract
 A callback fired when the Live Photo movie has captured all its media data, though all media has not yet been written to file.
 
 @param output
 The calling instance of AVCapturePhotoOutput.
 @param outputFileURL
 The URL to which the movie file will be written. This URL is equal to your AVCapturePhotoSettings.livePhotoMovieURL.
 @param resolvedSettings
 An instance of AVCaptureResolvedPhotoSettings indicating which capture features have been selected.
 
 @discussion
 When this callback fires, no new media is being written to the file. If you are displaying a "Live" badge, this is an appropriate time to dismiss it. The movie file itself is not done being written until the -captureOutput:didFinishProcessingLivePhotoToMovieFileAtURL:duration:photoDisplayTime:resolvedSettings:error: callback fires.
 */
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
  
}

/*!
 @method captureOutput:didFinishProcessingLivePhotoToMovieFileAtURL:duration:photoDisplayTime:resolvedSettings:error:
 @abstract
 A callback fired when the Live Photo movie is finished being written to disk.
 
 @param output
 The calling instance of AVCapturePhotoOutput.
 @param outputFileURL
 The URL where the movie file resides. This URL is equal to your AVCapturePhotoSettings.livePhotoMovieURL.
 @param duration
 A CMTime indicating the duration of the movie file.
 @param photoDisplayTime
 A CMTime indicating the time in the movie at which the still photo should be displayed.
 @param resolvedSettings
 An instance of AVCaptureResolvedPhotoSettings indicating which capture features have been selected.
 @param error
 An error indicating what went wrong if the outputFileURL is damaged.
 
 @discussion
 When this callback fires, the movie on disk is fully finished and ready for consumption.
 */
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {
  
}

/*!
 @method captureOutput:didFinishCaptureForResolvedSettings:error:
 @abstract
 A callback fired when the photo capture is completed and no more callbacks will be fired.
 
 @param output
 The calling instance of AVCapturePhotoOutput.
 @param resolvedSettings
 An instance of AVCaptureResolvedPhotoSettings indicating which capture features were selected.
 @param error
 An error indicating whether the capture was unsuccessful. Nil if there were no problems.
 
 @discussion
 This callback always fires last and when it does, you may clean up any state relating to this photo capture.
 */
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(nullable NSError *)error {
  
}

@end
