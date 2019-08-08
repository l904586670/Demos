//
//  BaseNode.m
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "BaseNode.h"

@implementation BaseNode

- (instancetype)init {
  if (self = [super init]) {
    [self setupDefaultValue];
  }
  return self;
}

- (void)setupDefaultValue {
  _name = @"untitled";
  _position = simd_make_float3(0.0);
  _rotation = simd_make_float3(0.0);
  _scale    = simd_make_float3(1.0);
  
  simd_float4x4 translateMatrix = [MathLibrary matrixWithTranslation:_position];
  simd_float4x4 rotateMatrix = [MathLibrary matrixWithRotation:_rotation];
  simd_float4x4 scaleMatrix = [MathLibrary matrixWithScaling:_scale];
  
  _modelMatrix = simd_mul(simd_mul(translateMatrix, rotateMatrix), scaleMatrix);
}

@end
