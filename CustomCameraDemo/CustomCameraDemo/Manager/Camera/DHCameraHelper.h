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

@interface AVCaptureDeviceDiscoverySession (Utilities)

// 获取前后摄像头的个数, 个数大于一可以切换摄像头
- (NSInteger)uniqueDevicePositionsCount;

@end

#pragma mark - /************************/

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

/**
 请求相册读写权限

 @param authorizedHandler 授权后回调
 @param deniedHandler 拒绝后回调, authStatus 拒绝原因状态码
 */
+ (void)requestAlbumPermission:(void(^)(void))authorizedHandler
                  denied:(void(^)(NSInteger authStatus))deniedHandler;

#pragma mark - AVCaptureDevice

// 获取视频输入设备
+ (AVCaptureDevice *)videoDeviceWithDevicePosition:(AVCaptureDevicePosition)position;

// 获取音频输入设备
+ (AVCaptureDevice *)audioDevice;

// 获取后置双摄输入设置
+ (AVCaptureDevice *)dualCameraDevice;


/**
 默认为后置双摄, 不支持为后置广角. 最后为前置广角

 @return 视频输入设备
 */
+ (AVCaptureDevice *)defaultCameraDevice;

+ (AVCaptureDeviceDiscoverySession *)deviceDiscoverySessionWith:(AVCaptureDevicePosition)devicePosition;

#pragma mark - Other

+ (UIImage *)fixOrientationWith:(UIImage *)image;


@end

NS_ASSUME_NONNULL_END
