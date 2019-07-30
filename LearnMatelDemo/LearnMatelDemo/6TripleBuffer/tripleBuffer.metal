//
//  tripleBuffer.metal
//  LearnMatelDemo
//
//  Created by User on 2019/7/30.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>
#import <simd/simd.h>

using namespace metal;

kernel void tripleShader (texture2d<float, access::write> texture_output [[texture(0)]], texture2d<float, access::sample> texture_input [[texture(1)]], constant float &timer [[buffer(0)]], uint2 gid [[thread_position_in_grid]])
{
  
  uint width = texture_output.get_width();
  uint height = texture_output.get_height();
  
  // 把纹理等比放大到输出大小
  //  float2 scale = float2(gid) / float2(width, height);
  //  uint2 scaleGid = uint2(scale * float2(input.get_width(), input.get_height()));
  //  float4 color = input.read(scaleGid);
  //  output.write(color, gid);
  
  float2 uv = float2(gid) / float2(width, height);
  constexpr sampler textureSampler(coord::normalized,
                                   address::repeat,
                                   min_filter::linear,
                                   mag_filter::linear,
                                   mip_filter::linear );
  float4 color = texture_input.sample(textureSampler, uv);
  half alphaInfo = clamp(sin(timer) + 1, 0.0, 1.0); 
  float4 result = float4(color * float4(alphaInfo, alphaInfo, alphaInfo, 1));
  
  texture_output.write(result, gid);
}
