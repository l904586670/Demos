//
//  DHCameraManager.h
//  CustomCameraDemo
//
//  Created by User on 2019/8/1.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, DHPhotoType) {
  DHPhotoTypeNormal = 0,    // 一般的拍照模式 -> jpg格式
  DHPhotoTypeRaw,           // 无损
  DHPhotoTypeLivePhoto,     // livePhoto
};


NS_ASSUME_NONNULL_BEGIN

@interface DHCameraManager : NSObject

// 会话输入流
@property(nonatomic, strong, readonly) AVCaptureSession *captureSession;

@property (nonatomic, assign) DHPhotoType photoType;

- (void)setupSession;
- (void)startSession;
- (void)stopSession;

- (void)captureStillImage;



@end

NS_ASSUME_NONNULL_END
