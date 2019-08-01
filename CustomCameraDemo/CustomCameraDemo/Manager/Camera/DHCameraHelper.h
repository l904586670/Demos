//
//  DHCameraHelper.h
//  CustomCameraDemo
//
//  Created by User on 2019/8/1.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DHCameraHelper : NSObject


/**
 请求查询摄像头 or 麦克风权限

 @param mediaType mediaType只能是 AVMediaTypeVideo or AVMediaTypeAudio
 @param authorizedHandler 同意权限后回调
 @param deniedHandler 拒绝后回调 authStatus == 1 受限制(家长控制) authStatus == 2 用户拒绝
 */
+ (void)requestPermissionWith:(AVMediaType)mediaType
                   authorized:(void(^)(void))authorizedHandler
                       denied:(void(^)(NSInteger authStatus))deniedHandler;

#pragma mark - AVCaptureDevice

// 获取视频输入设备
+ (AVCaptureDevice *)videoDeviceWithDevicePosition:(AVCaptureDevicePosition)position;

// 获取音频输入设备
+ (AVCaptureDevice *)audioDevice;

// 获取后置双摄输入设置
+ (AVCaptureDevice *)dualCameraDevice API_AVAILABLE(ios(10.2));


@end

NS_ASSUME_NONNULL_END
