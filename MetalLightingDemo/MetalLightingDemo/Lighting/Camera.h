//
//  Camera.h
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "BaseNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface Camera : BaseNode

// default 70.0
@property (nonatomic, assign) float fovDegrees;
@property (nonatomic, assign) float fovRadians;

@property (nonatomic, assign) float aspect;
@property (nonatomic, assign) float near;
@property (nonatomic, assign) float far;

@property (nonatomic, assign) simd_float4x4 projectionMatrix;
@property (nonatomic, assign) simd_float4x4 viewMatrix;

@end

NS_ASSUME_NONNULL_END
