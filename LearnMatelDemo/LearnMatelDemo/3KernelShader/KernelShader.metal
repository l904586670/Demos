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

// 在2d 笛卡尔坐标系中位置 gid
kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                    uint2 gid [[thread_position_in_grid]])
{
  // 获取纹理的宽高
  int width = output.get_width();
  int height = output.get_height();
  // 根据宽高 红绿渐变
  float red = float(gid.x) / float(width);
  float green = float(gid.y) / float(height);
  
  
  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  
  float distToCircle = dist(uv, float2(0), 0.5);
  bool inside = distToCircle < 0;
  
  output.write(inside ? float4(0) : float4(1, 0.7, 0, 1) * (1 - distToCircle), gid);
//  output.write(inside ? float4(0) : float4(red, green, 0, 1), gid);
}



