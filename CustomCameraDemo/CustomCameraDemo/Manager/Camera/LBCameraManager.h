//
//  LBCameraManager.h
//  CustomCameraDemo
//
//  Created by Rock on 2019/8/12.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LBCapturePhotoType) {
  LBCapturePhotoTypeNormal = 0, // 一般的拍照,输出为jpg
  LBCapturePhotoTypeRaw,        // 输出格式为dng的无损图
  LBCapturePhotoTypeLivePhoto,  // 输出动态壁纸
};

typedef void(^CapturePhotoBlock)(UIImage *resultImage);

@interface LBCameraManager : NSObject

// 会话输入流
@property(nonatomic, strong, readonly) AVCaptureSession *captureSession;

// 聚焦模式, default : auto
@property(nonatomic, assign) AVCaptureTorchMode torchMode;
// 闪光灯模式. default : Off
@property(nonatomic, assign) AVCaptureFlashMode flashMode;



// 照片一般为 AVCaptureSessionPresetPhoto, 视频 AVCaptureSessionPresetHigh. 默认为AVCaptureSessionPresetHigh
- (void)setSessionPreset:(AVCaptureSessionPreset)sessionPreset;

- (void)startSession;

- (void)stopSession;

// Camera Device Support
- (BOOL)canSwitchCameras;

/**
 切换摄像头

 @return YES -> Success
 */
- (BOOL)switchCameras;    

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


- (void)capturePhoto:(CapturePhotoBlock)completeHandler;

@end

NS_ASSUME_NONNULL_END
