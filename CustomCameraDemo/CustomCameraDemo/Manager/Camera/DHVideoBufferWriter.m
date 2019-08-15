//
//  DHVideoBufferWriter.m
//  CustomCameraDemo
//
//  Created by User on 2019/8/14.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "DHVideoBufferWriter.h"

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@interface DHVideoBufferWriter ()

@property (nonatomic, strong) dispatch_queue_t writeQueue;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;

@property (nonatomic, assign) BOOL readyToRecordVideo;
@property (nonatomic, assign) BOOL readyToRecordAudio;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, assign) UIDeviceOrientation deviceOrientation;

@end

@implementation DHVideoBufferWriter

- (instancetype)init {
  self = [super init];
  if (self) {
    _readyToRecordVideo = NO;
    _readyToRecordAudio = NO;
    
    _devicePosition = AVCaptureDevicePositionBack;
    
    [self motionManager];
  }
  return self;
}

#pragma mark - Lazy Methods

- (dispatch_queue_t)writeQueue {
  if (!_writeQueue) {
    NSString *label = [[NSBundle mainBundle].bundleIdentifier stringByAppendingString:@".avfoundation.videoWriterQueue"];
    _writeQueue = dispatch_queue_create([label cStringUsingEncoding:NSASCIIStringEncoding], NULL);
  }
  return _writeQueue;
}

- (CMMotionManager *)motionManager {
  if (!_motionManager) {
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1.0 / 3.0;
    if (!_motionManager.deviceMotionAvailable) {
      _motionManager = nil;
    }
    __weak typeof(self) weakSelf = self;
    [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler: ^(CMDeviceMotion *motion, NSError *error) {
      __strong  typeof(self) strongSelf = weakSelf;
      [strongSelf performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
    }];
  }
  
  return _motionManager;
}

- (void)dealloc {
  [_motionManager stopDeviceMotionUpdates];
}

#pragma mark - Public Methods


- (void)removeVideoOutputFile {
  if (!_outputVideoPath) {
    _outputVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempVideo.mov"];
  }
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:_outputVideoPath]) {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:_outputVideoPath error:&error];
    if (error) {
      NSAssert(NO, @"remove output file error : %@", error.localizedDescription);
    }
  }
}


- (void)startWrite {
  dispatch_async(self.writeQueue, ^{
    [self removeVideoOutputFile];
    
    NSError *error = nil;
    self->_assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:self->_outputVideoPath] fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error) {
      NSAssert(NO, @"creat asset writer error : %@", error.localizedDescription);
    }
  });
}

- (void)stopWrite:(void(^)(NSURL * _Nullable outputUrl, NSError * _Nullable error))handle {
  _readyToRecordVideo = NO;
  _readyToRecordAudio = NO;
  
  dispatch_async(self.writeQueue, ^{
    
    [self->_assetWriter finishWritingWithCompletionHandler:^{
      dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_assetWriter.status == AVAssetWriterStatusCompleted) {
          if (handle) {
            handle([NSURL fileURLWithPath:self->_outputVideoPath], nil);
          }
        } else {
          if (handle) {
            handle(nil, self->_assetWriter.error);
          }
        }

        [self->_assetWriter cancelWriting];
        self->_assetWriter = nil;
      });
    }];
  });
}


- (void)addDataBuffer:(CMSampleBufferRef)buffer mediaType:(AVMediaType)mediaType {
  CFRetain(buffer);
  dispatch_async(self.writeQueue, ^{
    if (mediaType == AVMediaTypeVideo) {
      if (!self->_readyToRecordVideo) {
        self->_readyToRecordVideo = [self setupAssetWriterVideoInput:CMSampleBufferGetFormatDescription(buffer)] == nil;
      }
      
      if ([self inputsReadyToRecord]) {
        [self writeSampleBuffer:buffer ofType:AVMediaTypeVideo];
      }
    } else if (mediaType == AVMediaTypeAudio) {
      if (!self->_readyToRecordAudio){
        self->_readyToRecordAudio = [self setupAssetWriterAudioInput:CMSampleBufferGetFormatDescription(buffer)] == nil;
      }
      if ([self inputsReadyToRecord]){
        [self writeSampleBuffer:buffer ofType:AVMediaTypeAudio];
      }
    }
    
    CFRelease(buffer);
  });
}

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType {
  if (_assetWriter.status == AVAssetWriterStatusUnknown) {
    if ([_assetWriter startWriting]){
      [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
    } else {
      NSLog(@"write sample buffer error : %@", _assetWriter.error);
    }
  }
  if (_assetWriter.status == AVAssetWriterStatusWriting) {
    if (mediaType == AVMediaTypeVideo) {
      if (!self.videoInput.readyForMoreMediaData){
        return;
      }
      if (![_videoInput appendSampleBuffer:sampleBuffer]){
        NSLog(@"append video buffer error : %@", _assetWriter.error);
      }
    } else if (mediaType == AVMediaTypeAudio){
      if (!self.audioInput.readyForMoreMediaData){
        return;
      }
      if (![_audioInput appendSampleBuffer:sampleBuffer]){
        NSLog(@"append audio buffer error : %@", _assetWriter.error);
      }
    }
  }
}

- (BOOL)inputsReadyToRecord {
  return _readyToRecordVideo && _readyToRecordAudio;
}

#pragma mark - Private Methods

/// 音频源数据写入配置
- (NSError *)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription {
  size_t aclSize = 0;
  const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
  const AudioChannelLayout *channelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription,&aclSize);
  NSData *dataLayout = aclSize > 0 ? [NSData dataWithBytes:channelLayout length:aclSize] : [NSData data];
  NSDictionary *settings = @{AVFormatIDKey: [NSNumber numberWithInteger: kAudioFormatMPEG4AAC],
                             AVSampleRateKey: [NSNumber numberWithFloat: currentASBD->mSampleRate],
                             AVChannelLayoutKey: dataLayout,
                             AVNumberOfChannelsKey: [NSNumber numberWithInteger: currentASBD->mChannelsPerFrame],
                             AVEncoderBitRatePerChannelKey: [NSNumber numberWithInt: 64000]};
  
  if ([self.assetWriter canApplyOutputSettings:settings forMediaType: AVMediaTypeAudio]){
    self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:settings];
    _audioInput.expectsMediaDataInRealTime = YES;
    if ([_assetWriter canAddInput:_audioInput]){
      [_assetWriter addInput:_audioInput];
    } else {
      return _assetWriter.error;
    }
  } else {
    return _assetWriter.error;
  }
  return nil;
}

/// 视频源数据写入配置
- (NSError *)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription {
  CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
  NSUInteger numPixels = dimensions.width * dimensions.height;
  CGFloat bitsPerPixel = numPixels < (640 * 480) ? 4.05 : 11.0;
  NSDictionary *compression = @{AVVideoAverageBitRateKey: [NSNumber numberWithInteger: numPixels * bitsPerPixel],
                                AVVideoMaxKeyFrameIntervalKey: [NSNumber numberWithInteger:30]};
  NSDictionary *settings = @{AVVideoCodecKey: AVVideoCodecH264,
                             AVVideoWidthKey: [NSNumber numberWithInteger:dimensions.width],
                             AVVideoHeightKey: [NSNumber numberWithInteger:dimensions.height],
                             AVVideoCompressionPropertiesKey: compression};
  
  if ([self.assetWriter canApplyOutputSettings:settings forMediaType:AVMediaTypeVideo]){
    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    _videoInput.expectsMediaDataInRealTime = YES;
    _videoInput.transform = [self transformFromCurrentVideoOrientationToOrientation:_videoOrientation];
    
    if ([_assetWriter canAddInput:_videoInput]){
      [_assetWriter addInput:_videoInput];
    } else {
      return _assetWriter.error;
    }
  } else {
    return _assetWriter.error;
  }
  return nil;
}

// 获取视频旋转矩阵
- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation {
  CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
  // 视频的播放方向
  CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:AVCaptureVideoOrientationPortrait];
  CGFloat angleOffset = 0.0;
  if (_devicePosition == AVCaptureDevicePositionBack) {
    angleOffset = videoOrientationAngleOffset - orientationAngleOffset + M_PI_2;
  } else if (_devicePosition == AVCaptureDevicePositionFront) {
    angleOffset = orientationAngleOffset - videoOrientationAngleOffset + M_PI_2;
  }

  
  NSLog(@"angleOffset : %@", @(angleOffset));

  return CGAffineTransformMakeRotation(angleOffset);
}

// 获取视频旋转角度, 默认home键在右为0度
- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation{
  CGFloat angle = 0.0;
  switch (orientation){
    case AVCaptureVideoOrientationPortrait:
      angle = 0.0;
      break;
    case AVCaptureVideoOrientationPortraitUpsideDown:
      angle = M_PI;
      break;
    case AVCaptureVideoOrientationLandscapeRight:
      angle = -M_PI_2;
      break;
    case AVCaptureVideoOrientationLandscapeLeft:
      angle = M_PI_2;
      break;
  }
  return angle;
}


// 如果设备获取方向不准确, 可以选择使用陀螺仪获取
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


// 从陀螺仪中获取当前设备方法
- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
  double x = deviceMotion.gravity.x;
  double y = deviceMotion.gravity.y;
  if (fabs(y) >= fabs(x)) {
    if (y >= 0) {
      _deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
      _videoOrientation  = AVCaptureVideoOrientationPortraitUpsideDown;
    } else {
      _deviceOrientation = UIDeviceOrientationPortrait;
      _videoOrientation  = AVCaptureVideoOrientationPortrait;
    }
  } else {
    if (x >= 0) {
      _deviceOrientation = UIDeviceOrientationLandscapeRight;
      _videoOrientation  = AVCaptureVideoOrientationLandscapeRight;
    } else {
      _deviceOrientation = UIDeviceOrientationLandscapeLeft;
      _videoOrientation  = AVCaptureVideoOrientationLandscapeLeft;
    }
  }
}


@end
