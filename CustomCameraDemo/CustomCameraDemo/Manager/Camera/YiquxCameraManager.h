//
//  YiquxCameraManager.h
//  SnakeScreenByLink
//
//  Created by Rock on 2018/5/10.
//  Copyright © 2018年 Yiqux. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger,YQCameraType) {
  YQCameraTypePhoto = 0,  // 仅相机, 不会请求麦克风权限
  YQCameraTypeVideo,
  YQCameraTypeAll
};

// *****************************************************************

@protocol YiquxCameraManagerDelegate <NSObject>

@optional

/**
 录制视频导出时出错

 @param error error
 */
- (void)mediaCaptureFailedWithError:(NSError *)error;

/**
 录制视频完成后video文件路径URL
 */
- (void)mediaCaptureVideoOutputFileUrl:(NSURL *)outputUrl;

- (void)mediaLockConfigurationFailedWithError:(NSError *)error;

@end

// *****************************************************************

/**
 提供摄像头相关的录制、照相、聚焦、曝光等方法
 */
@interface YiquxCameraManager : NSObject

@property(nonatomic, weak) id<YiquxCameraManagerDelegate> delegate;

@property(nonatomic, strong, readonly) AVCaptureSession *captureSession;

@property(nonatomic, assign, readonly) NSUInteger cameraCount;

@property(nonatomic, assign, readonly) BOOL cameraHasTorch;
// 当前摄像头是否支持闪光灯
@property(nonatomic, assign, readonly) BOOL cameraHasFlash;
// 是否支持点击聚焦
@property(nonatomic, assign, readonly) BOOL cameraSupportsTapToFocus;
// 是否支持点击曝光
@property(nonatomic, assign, readonly) BOOL cameraSupportsTapToExpose;

@property(nonatomic, assign) AVCaptureTorchMode torchMode;
@property(nonatomic, assign) AVCaptureFlashMode flashMode;

@property(nonatomic, assign) CGSize previewSize; // 截取图片的比例

// Session Configuration
- (BOOL)setupSessionWithCameraType:(YQCameraType)cameraType;
- (void)startSession;
- (void)stopSession;

// Camera Device Support
- (BOOL)switchCameras;        // 切换摄像头
- (BOOL)canSwitchCameras;

// Tap Methods
- (void)focusAtPoint:(CGPoint)point;  // 聚焦
- (void)exposeAtPoint:(CGPoint)point; // 曝光
- (void)resetFocusAndExposureModes;

- (void)videoZoomWithFactor:(CGFloat)factor;

/**
 拍照方法,返回当前照片

 @param completeHandler 返回照片回调,  stillImage可能为nil
 */
- (void)captureStillImage:(void(^)(UIImage *stillImage))completeHandler;

// video Recording
- (void)startRecording;
- (void)stopRecording;
- (BOOL)isRecording;

- (AVCaptureVideoOrientation)currentVideoOrientation;

@end
