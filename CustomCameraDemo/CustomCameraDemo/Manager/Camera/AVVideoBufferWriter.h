//
//  AVVideoBufferWriter.h
//  CustomCameraDemo
//
//  Created by User on 2019/8/14.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVVideoBufferWriter : NSObject

@property (nonatomic, strong) NSString *outputVideoPath;

- (void)startWrite;

- (void)stopWrite:(void(^)(NSURL * _Nullable outputUrl, NSError * _Nullable error))handle;

- (void)addDataBuffer:(CMSampleBufferRef)buffer mediaType:(AVMediaType)mediaType;

@end

NS_ASSUME_NONNULL_END
