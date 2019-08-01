//
//  DHCameraHelper.m
//  CustomCameraDemo
//
//  Created by User on 2019/8/1.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "DHCameraHelper.h"

@implementation DHCameraHelper


#pragma mark - Device
/**
 get device
 AVCaptureDeviceTypeBuiltInMicrophone : 麦克风
 AVCaptureDeviceTypeBuiltInWideAngleCamera : 广角相机. 一般可用
 AVCaptureDeviceTypeBuiltInTelephotoCamera : 长焦相机, 内置长焦相机，比广角相机的焦距长。这种类型只是将窄角设备与配备两种类型的摄像机的硬件上的宽角设备区分开来。要确定摄像机设备的实际焦距，可以检查AVCaptureDevice的format数组中的AVCaptureDeviceFormat对象。
 AVCaptureDeviceTypeBuiltInDualCamera : 广角相机和长焦相机的组合，创建了一个拍照，录像的AVCaptureDevice。具有和深度捕捉，增强变焦和双图像捕捉功能
 AVCaptureDeviceTypeBuiltInTrueDepthCamera : 相机和其他传感器的组合，创建了一个捕捉设备，能够拍照、视频和深度捕捉
 AVCaptureDeviceTypeBuiltInDuoCamera : iOS 10.2 之后添加自动变焦功能，该值功能被AVCaptureDeviceTypeBuiltInDualCamera替代
 */

+ (AVCaptureDevice *)videoDeviceWithDevicePosition:(AVCaptureDevicePosition)position {
  if (@available(iOS 10.0, *)) {
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera] mediaType:AVMediaTypeVideo position:position];
    return [discoverySession.devices firstObject];
  }
  return nil;
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

+ (AVCaptureDevice *)audioDevice {
  return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
}

#pragma mark - Permission

+ (void)requestPermissionWith:(AVMediaType)mediaType
                   authorized:(void(^)(void))authorizedHandler
                       denied:(void(^)(NSInteger authStatus))deniedHandler {
  if (mediaType != AVMediaTypeVideo || AVMediaTypeAudio != mediaType) {
    NSAssert(NO, @"mediaType must be AVMediaTypeVideo or AVMediaTypeAudio");
    return;
  }

  // 查询当前状态
  AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];

  switch (videoAuthStatus) {
      // 还未请求过权限
    case AVAuthorizationStatusNotDetermined: {
      [AVCaptureDevice requestAccessForMediaType:mediaType
                               completionHandler:^(BOOL granted) {
                                 
                                 if ([NSThread isMainThread]) {
                                   if (granted) {
                                     if (authorizedHandler) {
                                       authorizedHandler();
                                     }
                                     
                                   } else {
                                     if (deniedHandler) {
                                       deniedHandler(AVAuthorizationStatusDenied);
                                     }
                                   }
                                 } else {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     if (granted) {
                                       if (authorizedHandler) {
                                         authorizedHandler();
                                       }
                                     } else {
                                       if (deniedHandler) {
                                         deniedHandler(AVAuthorizationStatusDenied);
                                       }
                                     }
                                   });
                                 }
                               }];
      break;
    }
    case AVAuthorizationStatusRestricted:
      // 家长控制
      if (deniedHandler) {
        deniedHandler(videoAuthStatus);
      }
      break;
    case AVAuthorizationStatusDenied:
      // 拒绝授权
      if (deniedHandler) {
        deniedHandler(videoAuthStatus);
      }
      break;
    case AVAuthorizationStatusAuthorized:
      // 已授权
      if (authorizedHandler) {
        authorizedHandler();
      }
      break;
  }
}


@end
