//
//  MathLibrary.m
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "MathLibrary.h"

@implementation MathLibrary

+ (float)radiansFromDegrees:(float)degrees {
  return (degrees / 180.0) * M_PI;
}

+ (float)degreesFromRadians:(float)radians {
  return (radians / M_PI) * 180.0;
}

#pragma mark - matrix

+ (simd_float4x4)matrixWithTranslation:(simd_float3)translation {
  simd_float4x4 matrix = matrix_identity_float4x4;
  matrix.columns[3].x = translation.x;
  matrix.columns[3].y = translation.y;
  matrix.columns[3].z = translation.z;
  return matrix;
}

+ (simd_float4x4)matrixWithScaling:(simd_float3)scaling {
  simd_float4x4 matrix = matrix_identity_float4x4;
  matrix.columns[0].x = scaling.x;
  matrix.columns[1].y = scaling.y;
  matrix.columns[2].z = scaling.z;
  return matrix;
}

+ (simd_float4x4)matrixWithScale:(float)scale {
  simd_float4x4 matrix = matrix_identity_float4x4;
  matrix.columns[3].w = 1 / scale;
  return matrix;
}

+ (simd_float4x4)matrixWithRotationX:(float)angle {
  simd_float4x4 matrix = matrix_identity_float4x4;
  matrix.columns[1].y = cos(angle);
  matrix.columns[1].z = sin(angle);
  matrix.columns[2].y = -sin(angle);
  matrix.columns[2].z = cos(angle);
  return matrix;
}

+ (simd_float4x4)matrixWithRotationY:(float)angle {
  simd_float4x4 matrix = matrix_identity_float4x4;
  matrix.columns[0].x = cos(angle);
  matrix.columns[0].z = -sin(angle);
  matrix.columns[2].x = sin(angle);
  matrix.columns[2].z = cos(angle);
  return matrix;
}

+ (simd_float4x4)matrixWithRotationZ:(float)angle {
  simd_float4x4 matrix = matrix_identity_float4x4;
  matrix.columns[0].x = cos(angle);
  matrix.columns[0].y = sin(angle);
  matrix.columns[1].x = -sin(angle);
  matrix.columns[1].y = cos(angle);
  return matrix;
}

+ (simd_float4x4)matrixWithRotation:(simd_float3)angle {
  simd_float4x4 rotationX = [[self class] matrixWithRotationX:angle.x];
  simd_float4x4 rotationY = [[self class] matrixWithRotationY:angle.y];
  simd_float4x4 rotationZ = [[self class] matrixWithRotationZ:angle.z];

  return simd_mul(simd_mul(rotationX, rotationY), rotationZ);
//  return rotationX * rotationY * rotationZ;
}

+ (simd_float4x4)projectionFovMatrixWithFov:(float)fov near:(float)near far:(float)far aspect:(float)aspect lhs:(BOOL)lhs {
  float y = 1 / tan(fov * 0.5);
  float x = y / aspect;
  float z = lhs ? far / (far - near) : far / (near - far);
  simd_float4 X = simd_make_float4(x, 0, 0, 0);
  simd_float4 Y = simd_make_float4(0, y, 0, 0);
  simd_float4 Z = lhs ? simd_make_float4( 0,  0,  z, 1) : simd_make_float4( 0,  0,  z, -1);
  simd_float4 W = lhs ? simd_make_float4( 0,  0,  z * -near,  0) : simd_make_float4( 0,  0,  z * near,  0);
  
  simd_float4x4 matrix = matrix_identity_float4x4;
  matrix.columns[0] = X;
  matrix.columns[1] = Y;
  matrix.columns[2] = Z;
  matrix.columns[3] = W;
  return matrix;
}

// left-handed LookAt
+ (simd_float4x4)matrixWithEye:(simd_float3)eye center:(simd_float3)center up:(simd_float3)up {
  simd_float3 z = simd_normalize(eye - center);
  simd_float3 x = simd_normalize(simd_cross(up, z));
  simd_float3 y = simd_cross(z, x);
  simd_float3 w = simd_make_float3(simd_dot(x, -eye), simd_dot(y, -eye), simd_dot(z, -eye));
  
  simd_float4x4 matrix = matrix_identity_float4x4;
  matrix.columns[0] = simd_make_float4(x.x, y.x, z.x, 0);
  matrix.columns[1] = simd_make_float4(x.y, y.y, z.y, 0);
  matrix.columns[2] = simd_make_float4(x.z, y.z, z.z, 0);
  matrix.columns[3] = simd_make_float4(w.x, w.y, x.z, 1);
  return matrix;
}

+ (simd_float4x4)matrixWithOrthoLeft:(float)left right:(float)right bottom:(float)bottom top:(float)top near:(float)near far:(float)far {  
  simd_float4x4 matrix = matrix_identity_float4x4;
  matrix.columns[0] = simd_make_float4(2 / (right - left), 0, 0, 0);
  matrix.columns[1] = simd_make_float4(0, 2 / (top - bottom), 0, 0);
  matrix.columns[2] = simd_make_float4(0, 0, 1 / (far - near), 0);
  matrix.columns[3] = simd_make_float4((left + right) / (left - right), (top + bottom) / (bottom - top), near / (near - far), 1);
  return matrix;
}

+ (simd_float3x3)upperLeftWithMatrix:(simd_float4x4)matrix {
//  simd_float3 x = matrix.columns[0].xyz;
//  simd_float3 y = matrix.columns[1].xyz;
//  simd_float3 z = matrix.columns[2].xyz;
  simd_float3x3 result = matrix_identity_float3x3;
  result.columns[0] = matrix.columns[0].xyz;
  result.columns[1] = matrix.columns[1].xyz;
  result.columns[2] = matrix.columns[2].xyz;
  return result;
}

@end
