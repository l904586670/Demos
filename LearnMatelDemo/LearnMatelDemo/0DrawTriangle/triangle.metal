//
//  triangle.metal
//  LearnMatelDemo
//
//  Created by User on 2019/7/20.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>

#import "Common.h"
using namespace metal;

// 传入的顶点数据类型
typedef struct
{
  vector_float4 position;
  vector_float4 colorCoordinate;
} LYVertex;

// 顶点描述符的输出类型, 传给GPU图元描述符. -> 到片段描述符
typedef struct {
  float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
  float4 colorCoordinate; // 颜色坐标，会做插值处理
} RasterizerData;

// 定义矩阵 Uniforms
//typedef struct {
//  float4x4 mvp_matrix;
//} Uniforms;


// 返回给片元着色器的结构体
vertex RasterizerData vertexShader( constant LYVertex *vertexArray [[ buffer(0) ]],
             constant Uniforms &uniforms [[ buffer(1) ]],
             uint vertexID [[ vertex_id ]] // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
            )
{ // buffer表明是缓存数据，0是索引
  RasterizerData out;
  
  out.clipSpacePosition = uniforms.mvp_matrix * vertexArray[vertexID].position;
  out.colorCoordinate = vertexArray[vertexID].colorCoordinate;
  return out;
}

// stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
fragment float4 fragmentShader( RasterizerData interpolated [[stage_in]] )
{
  return interpolated.colorCoordinate;
}

