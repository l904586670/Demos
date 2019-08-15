//
//  AVCameraManager.h
//  CustomCameraDemo
//
//  Created by User on 2019/8/15.
//  Copyright © 2019 Rock. All rights reserved.
//
// 支持为 IOS 10.0~

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AVCaptureMode) {
  AVCaptureModeVideo = 0,
  AVCaptureModePhoto,
};

typedef void(^CapturePhotoResult)(UIImage * _Nullable resultImage, NSData *imgData);


@protocol AVCameraManagerCapturePhotoDelegate <NSObject>

@optional;

- (void)CameraWillCapturePhotoAnimation;

// 相机开始处理图片素材. state -> YES 开始. state -> NO 结束. 耗时做一些菊花动画
- (void)CameraPhotoProcessingStart;

- (void)CameraPhotoProcessingEnd:(NSData *)imgData error:(NSError *)error;

- (void)CameraFinishCaptureWithError:(NSError *)error;

@end


@interface AVCameraManager : NSObject

@property (nonatomic, strong) dispatch_queue_t sessionQueue;

// 会话输入流
@property(nonatomic, strong, readonly) AVCaptureSession *session;

@property(nonatomic, assign, readonly) CGFloat videoZoomFactor;

@property(nonatomic, assign, readonly) CGFloat videoMaxZoomFactor;

// 聚焦模式, default : auto
@property (nonatomic, assign) AVCaptureTorchMode torchMode;
// 闪光灯模式. default : Off
@property (nonatomic, assign) AVCaptureFlashMode flashMode;

// 拍照是否镜像. 系统相机默认为镜像. 默认为不镜像
@property(nonatomic, assign) BOOL photoMirror;

@property (nonatomic, assign, readonly) AVCaptureMode captureMode;

@property (nonatomic, weak) id<AVCameraManagerCapturePhotoDelegate> photoDelegate;

- (void)startSession;
- (void)stopSession;

#pragma mark - 点击方法

/**
 聚焦
 */
- (void)focusAtPoint:(CGPoint)point;  // 聚焦

/**
 曝光
 */
- (void)exposeAtPoint:(CGPoint)point; // 曝光

/**
 重置聚焦和曝光, 点设置为{0.5, 0.5}
 */
- (void)resetFocusAndExposureModes;

- (void)videoZoomWithFactor:(CGFloat)factor;

- (void)switchCamera;
- (void)capturePhoto:(CapturePhotoResult)completeHandler;
- (void)changeCaptureMode:(AVCaptureMode)captureMode;

- (void)startRecording;
- (void)stopRecording:(void(^)(NSURL * _Nullable outputURL, NSError * _Nullable error))resultBlock;

@end

NS_ASSUME_NONNULL_END
