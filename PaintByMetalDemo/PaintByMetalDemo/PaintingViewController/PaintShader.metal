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
fragment float4 fragmentPaintShader( PaintVertexOut in [[stage_in]], texture2d<float, access::sample> brushTexture [[texture(0)]], constant float4 &brushColor [[buffer(0)]], float2 pointCoord [[point_coord]], float4 lastColor [[color(0)]] )
{
  constexpr sampler textureSampler(coord::normalized,
                                   address::repeat,
                                   min_filter::linear,
                                   mag_filter::linear,
                                   mip_filter::linear );
//  constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
  float4 texel = brushTexture.sample(textureSampler, pointCoord);
  half alphaInfo = clamp(texel.a, 0.0, 1.0);
  
//  return mix(lastColor * brushColor * alphaInfo);
  return float4(lastColor * brushColor * alphaInfo);
}
