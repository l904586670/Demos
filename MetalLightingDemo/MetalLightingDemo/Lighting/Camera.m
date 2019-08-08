//
//  Camera.m
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "Camera.h"

@implementation Camera

- (instancetype)init {
  self = [super init];
  if (self) {
    _fovDegrees = 70.0;
    _aspect = 1.0;
    _near = 0.001;
    _far = 100.0;
  }
  return self;
}

#pragma mark - Getter

- (float)fovRadians {
  return [MathLibrary radiansFromDegrees:_fovDegrees];
}

- (simd_float4x4)projectionMatrix {
  return [MathLibrary projectionFovMatrixWithFov:_fovRadians
                                            near:_near
                                             far:_far
                                          aspect:_aspect
                                             lhs:YES];
}

- (simd_float4x4)viewMatrix {
  simd_float4x4 translateMatrix = [MathLibrary matrixWithTranslation:self.position];
  simd_float4x4 rotateMatrix = [MathLibrary matrixWithRotation:self.rotation];
  simd_float4x4 scaleMatrix = [MathLibrary matrixWithScaling:self.scale];
  
  return simd_inverse(simd_mul(simd_mul(translateMatrix, scaleMatrix),rotateMatrix));
}

@end
