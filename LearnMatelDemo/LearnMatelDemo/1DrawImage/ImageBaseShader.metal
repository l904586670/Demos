//
//  ImageBaseShader.metal
//  LearnMatelDemo
//
//  Created by User on 2019/7/23.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct
{
  vector_float4 position;
  vector_float2 textureCoord;
} Vertex_input;


// 顶点描述符的输出类型, 传给GPU图元描述符. -> 到片段描述符
typedef struct {
  float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
  float2 textureCoordinate; 
} Vertex_out;


// 顶点shader 函数
// 修饰符  返回类型 参数 顶点数据 顶点索引
vertex Vertex_out imgVertexShader( uint vertexID [[vertex_id]], constant Vertex_input *vertexData [[buffer(0)]] )
{
  Vertex_out vertex_out;
  vertex_out.clipSpacePosition = vertexData[vertexID].position;
  vertex_out.textureCoordinate = vertexData[vertexID].textureCoord;
  return vertex_out;
}

// 片段shader 函数
fragment float4 imgFragmentShader( Vertex_out fragment_input [[stage_in]], texture2d<half> imgTexture [[ texture(0) ]] )
{
  // sampler是取样器.
//  mag_filter模式指定当区域大于纹理大小时，采样器应如何计算返回的颜色；min_filter模式指定当区域小于纹理大小时，采样器应如何计算返回的颜色。 为两个滤镜设置线性linear模式可使采样器平均给定纹理坐标周围的纹素颜色，从而使输出图像更平滑。
  constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
  
  half4 colorSample = imgTexture.sample(textureSampler, fragment_input.textureCoordinate); // 得到纹理对应位置的颜色
  return float4(colorSample);
}

