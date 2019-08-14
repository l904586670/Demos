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

- (void)removeVideoOutputFile;

- (void)startWrite;

- (void)stopWrite:(void(^)(NSURL * _Nullable outputUrl, NSError * _Nullable error))handle;

- (void)writeData:(AVCaptureConnection *)connection
            video:(AVCaptureConnection*)video
            audio:(AVCaptureConnection *)audio
           buffer:(CMSampleBufferRef)buffer;

@end

NS_ASSUME_NONNULL_END
