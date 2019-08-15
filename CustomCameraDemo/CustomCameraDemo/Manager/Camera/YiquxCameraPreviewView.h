//
//  YiquxCameraPreviewView.h
//  SnakeScreenByLink
//
//  Created by Rock on 2018/5/10.
//  Copyright © 2018年 Yiqux. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession, AVCaptureConnection;

// *****************************************************************

@protocol YiquxCameraPreviewViewDelegate <NSObject>

@optional

/**
 对某点聚焦 (单击触发)

 @param point point为转换过坐标系后的point
 */
- (void)tappedToFocusAtPoint:(CGPoint)point;

/**
 对某点曝光 (双击触发)

 @param point point为转换过坐标系后的point
 */
- (void)tappedToExposeAtPoint:(CGPoint)point;

/**
 复原 (双指双击触发)
 */
- (void)tappedToResetFocusAndExposure;

- (void)videoZoomWithFactor:(CGFloat)zoom;

@end

// *****************************************************************

/**
 提供摄像头可视化界面
 */
@interface YiquxCameraPreviewView : UIView

@property(nonatomic, weak) id<YiquxCameraPreviewViewDelegate> delegate;

@property(nonatomic, strong) AVCaptureSession *session;

@property(nonatomic, strong, readonly) AVCaptureConnection *connection;

@property(nonatomic, assign) BOOL tapToFocusEnabled;
@property(nonatomic, assign) BOOL tapToExposeEnabled;

@end
