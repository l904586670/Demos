//
//  SphereRefraction.metal
//  SphereRefractionDemo
//
//  Created by User on 2019/8/7.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void SphereRefractionKernel (texture2d<float, access::sample>input [[texture(0)]], texture2d<float, access::write>output [[texture(1)]], constant float2& center [[buffer(0)]], constant float& radius [[buffer(1)]], constant float &refractiveIndex [[buffer(2)]], uint2 gid [[thread_position_in_grid]])
{
  // GPUImage refractiveIndex -> 0.71
  uint width = output.get_width();
  uint height = output.get_height();
  
  // 当前点归一化后的位置
  float2 coordinate = float2(gid) / float2(width, height);
  
  // 输出尺寸的宽高比
  float outputFactor = (float)width / (float)height;
  float textureFactor = (float)input.get_width() / (float)input.get_height();
  // 背景图采取纹理坐标
  float2 coordinateInTexture = coordinate;
  // 球形区域采取纹理坐标
  float2 textureCoordinateToUse = coordinate;
  
  // 计算乘以宽高比的位置, 确保纹理铺满, 确保球形
  if (outputFactor > textureFactor) {
    // 需要改变y坐标, (裁去部分内容)
    coordinateInTexture = float2(coordinate.x, coordinate.y * outputFactor + 0.5 - 0.5 * outputFactor);
    textureCoordinateToUse = float2(coordinate.x / outputFactor + 0.5 - 0.5 / outputFactor, coordinate.y);

  } else {
    // 需要改变x坐标
    coordinateInTexture = float2(coordinate.x * outputFactor + 0.5 - 0.5 * outputFactor, coordinate.y);
    textureCoordinateToUse = float2(coordinate.x, coordinate.y / outputFactor + 0.5 - 0.5 / outputFactor);
  }
  
  // 获取当前点到球体中心的距离
  float distanceFromCenter = distance(center, textureCoordinateToUse);
  // 判断是否在球体内 在球内 checkForPresenceWithinSphere = 1.0; 不在球内 = 0.0
  float checkForPresenceWithinSphere = step(distanceFromCenter, radius);
  
  
  distanceFromCenter = distanceFromCenter / radius;
  float normalizedDepth = radius * sqrt(1.0 - distanceFromCenter * distanceFromCenter);
  
  float3 sphereNormal = normalize(float3(textureCoordinateToUse - center, normalizedDepth));
  
  float3 refractedVector = refract(float3(0.0, 0.0, -1.0), sphereNormal, refractiveIndex);
  
  constexpr sampler textureSampler(coord::normalized,
                                   address::repeat,
                                   min_filter::linear,
                                   mag_filter::linear,
                                   mip_filter::linear );
//
  float4 color = checkForPresenceWithinSphere <= 0.0 ? input.sample(textureSampler, coordinateInTexture) : input.sample(textureSampler, float2((-refractedVector.xy + 1.0) * 0.5));
  output.write(color, gid);
}

