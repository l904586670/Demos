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

struct PaintVertexIn {
  packed_float2 position;
};

struct PaintVertexOut {
  float4 position [[position]];
  float size [[point_size]];
};

struct BaseVertexIn {
  packed_float2 position;
  packed_float2 textureCoordinate;
};

struct BaseVertexOut {
  float4 computedPosition [[position]];
  float2 textureCoordinate;
};

/*
 地址空间修饰符 device、threadgroup、constant、thread
 顶点函数（vertex）、像素函数（fragment）、通用计算函数（kernel）的指针或引用参数，都必须带有地址空间修饰符号
 device 读写 , constant 只读
 纹理对象总是在device地址空间分配内存，所以纹理类型可以省略修饰符
 thread地址空间用于每个线程内部的内存分配，被thread修饰的变量在其他线程无法访问，在图形绘制或是通用计算函数内声明的变量是thread地址空间分配
 */


vertex PaintVertexOut vertexPaintShader( constant PaintVertexIn *vertexIn [[buffer(0)]], constant float &pointSize [[buffer(1)]], uint vid [[vertex_id]] )
{ // buffer表明是缓存数据，0是索引
  PaintVertexOut out;
  float4 in_position = float4(vertexIn[vid].position, 0.0f, 1.0f);
  
  out.position = in_position;
  out.size = pointSize;
  return out;
}

// stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
fragment float4 fragmentPaintShader( PaintVertexOut in [[stage_in]], texture2d<float, access::sample> brushTexture [[texture(0)]], device const float4& brushColor [[ buffer(0) ]], float2 pointCoord [[point_coord]], float4 lastColor [[color(0)]])
{
  constexpr sampler textureSampler(coord::normalized,
                                   address::repeat,
                                   min_filter::linear,
                                   mag_filter::linear,
                                   mip_filter::linear );
//  constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
  float4 texel = brushTexture.sample(textureSampler, pointCoord);
  float alphaInfo = clamp(texel.a, 0.0, 1.0);

  return mix(lastColor, brushColor, alphaInfo);
}

fragment float4 fragemntEarseShader (PaintVertexOut in [[stage_in]], texture2d<float, access::sample> brushTexture [[texture(0)]], float2 pointCoord [[point_coord]], float4 lastColor [[color(0)]])
{
  constexpr sampler textureSampler(coord::normalized,
                                   address::repeat,
                                   min_filter::linear,
                                   mag_filter::linear,
                                   mip_filter::linear);

  float4 texel = brushTexture.sample(textureSampler, pointCoord);
  return float4(lastColor * texel.a);
}


vertex BaseVertexOut basic_vertex(const device BaseVertexIn* vertex_array [[ buffer(0) ]], unsigned int vid [[ vertex_id ]]) {
  BaseVertexIn v = vertex_array[vid];
  BaseVertexOut outVertex = BaseVertexOut();
  outVertex.computedPosition = float4(v.position, 0.0, 1.0);
  outVertex.textureCoordinate = v.textureCoordinate;
  return outVertex;
}


fragment float4 basic_fragment(BaseVertexOut interpolated [[stage_in]], texture2d<float> sourceTexture [[ texture(0) ]], device const float& alpha [[ buffer(0) ]]) {
  constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
  float4 dstColor = sourceTexture.sample(textureSampler, interpolated.textureCoordinate);
  return float4(dstColor[0], dstColor[1], dstColor[2], dstColor[3] * alpha);
}

fragment float4 mask_fragment(BaseVertexOut interpolated [[stage_in]], texture2d<float> sourceTexture [[ texture(0) ]], texture2d<float> maskTexture [[ texture(1) ]]) {
  constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
  float4 sourceColor = sourceTexture.sample(textureSampler, interpolated.textureCoordinate);
  float4 maskColor = maskTexture.sample(textureSampler, interpolated.textureCoordinate);
  return float4(sourceColor.rgb, sourceColor.a * maskColor.a);
}


