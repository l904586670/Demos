//
//  MathLibrary.h
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface MathLibrary : NSObject

+ (float)radiansFromDegrees:(float)degrees;

+ (float)degreesFromRadians:(float)radians;


+ (simd_float4x4)matrixWithTranslation:(simd_float3)translation;

+ (simd_float4x4)matrixWithScaling:(simd_float3)scaling;

+ (simd_float4x4)matrixWithScale:(float)scale;

+ (simd_float4x4)matrixWithRotationX:(float)angle;

+ (simd_float4x4)matrixWithRotationY:(float)angle;

+ (simd_float4x4)matrixWithRotationZ:(float)angle;

+ (simd_float4x4)matrixWithRotation:(simd_float3)angle;

+ (simd_float4x4)projectionFovMatrixWithFov:(float)fov
                                       near:(float)near
                                        far:(float)far
                                     aspect:(float)aspect
                                        lhs:(BOOL)lhs;

// left-handed LookAt
+ (simd_float4x4)matrixWithEye:(simd_float3)eye
                        center:(simd_float3)center
                            up:(simd_float3)up;

+ (simd_float4x4)matrixWithOrthoLeft:(float)left
                               right:(float)right
                              bottom:(float)bottom
                                 top:(float)top
                                near:(float)near
                                 far:(float)far;

+ (simd_float3x3)upperLeftWithMatrix:(simd_float4x4)matrix;

@end

NS_ASSUME_NONNULL_END
