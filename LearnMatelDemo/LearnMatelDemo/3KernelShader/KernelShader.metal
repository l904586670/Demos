//
//  KernelShader.metal
//  LearnMatelDemo
//
//  Created by User on 2019/7/27.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

float dist(float2 point, float2 center, float radius)
{
  return length(point - center) - radius;
}

float smootherstep(float e1, float e2, float x)
{
  // clamp 区间限定函数
  x = clamp((x - e1) / (e2 - e1), 0.0, 1.0);
  return x * x * x * (x * (x * 6 - 15) + 10);
}

// 在2d 笛卡尔坐标系中位置 gid
kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                    uint2 gid [[thread_position_in_grid]])
{
  // 获取纹理的宽高
  uint width = output.get_width();
  uint height = output.get_height();
//  // 根据宽高 红绿渐变
//  float red = float(gid.x) / float(width);
//  float green = float(gid.y) / float(height);
  
  // 在坐标中的位置
  float2 uv = float2(gid) / float2(width, height); // [0 ~ 1.0]
  uv = uv * 2.0 - 1.0;    // -> [-1.0 ~ 1.0];

  float radius = 0.5; // 球体半径
  float distance = dist(uv, float2(0), radius);

  float xMax = width/height;
  float4 sun = float4(1, 0.7, 0, 1) * (1 - distance); // 当前点的颜色
  float4 planet = float4(0);

  float m = smootherstep(radius - 0.005, radius + 0.005, length(uv - float2(xMax-1, 0)));
  float4 pixel = mix(planet, sun, m);
  output.write(pixel, gid);
}

//float4 gridColor()
//{
//  float2 uv = float2(gid) / float2(wdith, height); // [0 ~ 1.0]
//  float3 color = float3(0.7);
//  //
//  if(fmod(uv.x, 0.1) < 0.005 || fmod(uv.y, 0.1) < 0.005) color = float3(0,0,1);
//    //
//  float2 uv_ext = uv * 2.0 - 1.0;
//  if(abs(uv_ext.x) < 0.01 || abs(uv_ext.y) < 0.01) color = float3(1, 0, 0);
//
//  if(abs(uv_ext.x - uv_ext.y) < 0.02 || abs(uv_ext.x + uv_ext.y) < 0.02) color = float3(0, 1, 0);
//  return float4(color, 1);
//}

