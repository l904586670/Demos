//
//  Shader.metal
//  PaintByMetalDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>

// 只能引用同一目录下文件, 一般引入到 header.pch中
#import "CommonDefinition.h"
using namespace metal;

typedef struct {
  float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
  float pointSize [[point_size]];
  float4 colorCoordinate; // 颜色坐标，会做插值处理
  float2 textureCoordinate;
} RasterizerData;


// 返回给片元着色器的结构体
vertex RasterizerData vertexShaderMain( constant VertexInfo *vertexArray [[ buffer(0) ]],
                                       constant UniformsMatrix &uniMatrix [[ buffer(1) ]],
                                       uint vertexID [[ vertex_id ]] // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
                                       )
{ // buffer表明是缓存数据，0是索引
  RasterizerData out;
  // 矩阵从右向左乘
  out.clipSpacePosition = uniMatrix.projection_matrix * uniMatrix.view_matrix * uniMatrix.model_matrix * vertexArray[vertexID].position;
  out.colorCoordinate = vertexArray[vertexID].colorCoordinate;
  out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
  return out;
}

// stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
fragment float4 fragmentShaderMain( RasterizerData fragment_input [[stage_in]], texture2d<half> imgTexture [[ texture(0) ]] )
{
  // sampler是取样器. 图片
  constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
  half4 textureTex = imgTexture.sample(textureSampler, fragment_input.textureCoordinate);
  half4 colorTex = half4(fragment_input.colorCoordinate);
  return float4(textureTex * colorTex);
}
