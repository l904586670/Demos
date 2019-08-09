//
//  mirrorShader.metal
//  VideoMirrorDemo
//
//  Created by User on 2019/8/9.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void mirrorKernel(texture2d<float, access::write> output [[texture(0)]], texture2d<float, access::sample> input [[texture(1)]], constant float &mirrorType [[buffer(0)]], uint2 gid [[thread_position_in_grid]] )
{
  uint width = output.get_width();
  uint height = output.get_height();
  
  float2 uv = float2(gid) / float2(width, height);
  float2 uvFlipped;
  uvFlipped.y = uv.y;
  
  if(mirrorType == 0.0) {
    if(uv.x < 0.5) {
      uvFlipped.x = (1.0 - uv.x);
      
    } else {
      uvFlipped.x = uv.x;
    }
  } else if (mirrorType == 1.0) {
    if(uv.x > 0.5) {
      uvFlipped.x = (1.0 - uv.x);
    } else {
      uvFlipped.x = uv.x;
    }
  } else {
    uvFlipped.x = uv.x;
  }
  
  constexpr sampler textureSampler (mag_filter::linear,
                                    min_filter::linear);
  
  float4 color = input.sample(textureSampler, uvFlipped);
  
  output.write(color, gid);
}


kernel void leftToRight(texture2d<float, access::write> output [[texture(0)]], texture2d<float, access::sample> input [[texture(1)]], constant float &mirrorType [[buffer(0)]], uint2 gid [[thread_position_in_grid]] )
{
  uint width = output.get_width();
  uint height = output.get_height();
  
  float2 uv = float2(gid) / float2(width, height);
  float2 uvFlipped;
  uvFlipped.y = uv.y;
  
  if(uv.x > 0.5) {
    uvFlipped.x = (1.0 - uv.x);
  } else {
    uvFlipped.x = uv.x;
  }
  
  constexpr sampler textureSampler (mag_filter::linear,
                                    min_filter::linear);
  
  float4 color = input.sample(textureSampler, uvFlipped);
  output.write(color, gid);
}

kernel void downToUp(texture2d<float, access::write> output [[texture(0)]], texture2d<float, access::sample> input [[texture(1)]], constant float &mirrorType [[buffer(0)]], uint2 gid [[thread_position_in_grid]] )
{
  uint width = output.get_width();
  uint height = output.get_height();
  
  float2 uv = float2(gid) / float2(width, height);
  float2 uvFlipped;
  
  uvFlipped.x = uv.x;
  if(uv.y < 0.5) {
    uvFlipped.y = (1.0 - uv.y);
  } else {
    uvFlipped.y = uv.y;
  }
  
  constexpr sampler textureSampler (mag_filter::linear,
                                    min_filter::linear);
  
  float4 color = input.sample(textureSampler, uvFlipped);
  output.write(color, gid);
}


kernel void downRightSlice(texture2d<float, access::write> output [[texture(0)]], texture2d<float, access::sample> input [[texture(1)]], constant float &mirrorType [[buffer(0)]], uint2 gid [[thread_position_in_grid]] )
{
  uint width = output.get_width();
  uint height = output.get_height();
  
  float2 uv = float2(gid) / float2(width, height);
  float2 uvFlipped;
  
  uvFlipped.x = uv.x;
  uvFlipped.y = uv.y;
  
  if(uv.y >= 0.5) {
    float slope = (1.0 - uv.y) / (0.0 - uv.x);
    if(slope > -0.5) {
      uvFlipped.x = (1.0 - (uv.y)) * 2.0;
      uvFlipped.y = (1.0 - (uv.x) / 2.0);
    }
  }
  
  constexpr sampler textureSampler (mag_filter::linear,
                                    min_filter::linear);
  
  float4 color = input.sample(textureSampler, uvFlipped);
  output.write(color, gid);
}

kernel void downLeftSlice(texture2d<float, access::write> output [[texture(0)]], texture2d<float, access::sample> input [[texture(1)]], constant float &mirrorType [[buffer(0)]], uint2 gid [[thread_position_in_grid]] )
{
  uint width = output.get_width();
  uint height = output.get_height();
  
  float2 uv = float2(gid) / float2(width, height);
  float2 uvFlipped;
  
  uvFlipped.x = uv.x;
  uvFlipped.y = uv.y;
  
  if(uv.y >= 0.5) {
    float slope = (1.0 - uv.y) / (1.0 - uv.x);
    if(slope < 0.5) {
      uvFlipped.x = (uv.y - 0.5) * 2.0;
      uvFlipped.y = (uv.x + 1.0) / 2.0;
    }
  }
  
  constexpr sampler textureSampler (mag_filter::linear,
                                    min_filter::linear);
  
  float4 color = input.sample(textureSampler, uvFlipped);
  output.write(color, gid);
}


kernel void centerRightSlice(texture2d<float, access::write> output [[texture(0)]], texture2d<float, access::sample> input [[texture(1)]], constant float &mirrorType [[buffer(0)]], uint2 gid [[thread_position_in_grid]] )
{
  uint width = output.get_width();
  uint height = output.get_height();
  
  float2 uv = float2(gid) / float2(width, height);
  float2 uvFlipped;
  
  uvFlipped.x = uv.x;
  uvFlipped.y = uv.y;
  
  if(uv.y <= 0.5) {
    float slope = (0.5 - uv.y) / (0.0 - uv.x);
    if(abs(slope) > 0.5) {
      uvFlipped.x = (1.0 - (uv.y) * 2.0);
      uvFlipped.y = (1.0 - (uv.x)) / 2.0;
    }
    
  } else if(uv.y >= 0.5) {
    float slope = (1.0 - uv.y) / (0.0 - uv.x);
    if(slope > -0.5) {
      uvFlipped.x = (1.0 - (uv.y)) * 2.0;
      uvFlipped.y = (1.0 - (uv.x) / 2.0);
    }
  }
  
  constexpr sampler textureSampler (mag_filter::linear,
                                    min_filter::linear);
  
  float4 color = input.sample(textureSampler, uvFlipped);
  output.write(color, gid);
}

