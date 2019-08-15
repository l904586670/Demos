//
//  DHVideoBufferWriter.h
//  CustomCameraDemo
//
//  Created by User on 2019/8/14.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DHVideoBufferWriter : NSObject

@property (nonatomic, assign, readonly) AVCaptureVideoOrientation videoOrientation;

@property (nonatomic, strong) NSString *outputVideoPath;

@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;

// 根据当前buffer 配置视频写入
- (NSError *)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription;

// 根据当前buffer 配置音频写入
- (NSError *)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription;

- (void)startWrite;

- (void)stopWrite:(void(^)(NSURL * _Nullable outputUrl, NSError * _Nullable error))handle;

- (void)addDataBuffer:(CMSampleBufferRef)buffer mediaType:(AVMediaType)mediaType;

@end

NS_ASSUME_NONNULL_END
