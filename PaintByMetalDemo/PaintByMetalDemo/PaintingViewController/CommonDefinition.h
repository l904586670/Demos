//
//  CommonDefinition.h
//  LearnMatelDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#ifndef CommonDefinition_h
#define CommonDefinition_h

#import <simd/simd.h>

// 顶点数据结构体
typedef struct {
  vector_float4 position;           // 坐标
  vector_float4 colorCoordinate;    // 颜色
  vector_float2 textureCoordinate;  // 纹理坐标
} VertexInfo;


typedef struct {
  matrix_float4x4 model_matrix;      // 模型矩阵 把物体从局部空间转换到世界空间
  matrix_float4x4 view_matrix;       // 观察矩阵 把物体从世界空间转换到观察空间(摄像空间)
  matrix_float4x4 projection_matrix; // 投影矩阵 将顶点坐标从观察变换到裁剪空间
} UniformsMatrix;


#endif /* CommonDefinition_h */
