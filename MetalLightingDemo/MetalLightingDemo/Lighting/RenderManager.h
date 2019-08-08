//
//  RenderManager.h
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface RenderManager : NSObject

@property (nonatomic, strong, readonly) id<MTLDevice> deivce;
@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;
@property (nonatomic, assign) MTLPixelFormat colorPixelFormat;
@property (nonatomic, strong, readonly) id<MTLLibrary> library;

+ (instancetype)instance;

@end

NS_ASSUME_NONNULL_END
