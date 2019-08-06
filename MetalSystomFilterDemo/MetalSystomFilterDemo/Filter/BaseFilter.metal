//
//  BaseFilter.metal
//  MetalSystomFilterDemo
//
//  Created by User on 2019/8/6.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


// 色温 temperature:[-1.0, 1.0]
float3 colorTemperature(float3 color, float temperature) {
  float3 warmFilter = float3(0.93, 0.54, 0.0);
  
  float3x3 RGBtoYIQ = float3x3(float3(0.299, 0.587, 0.114),
                               float3(0.596, -0.274, -0.322),
                               float3(0.212, -0.523, 0.311));
  float3x3 YIQtoRGB = float3x3(float3(1.0, 0.956, 0.621),
                               float3(1.0, -0.272, -0.647),
                               float3(1.0, -1.105, 1.702));
  
  float3 yiq = RGBtoYIQ * color;
  yiq.b = clamp(yiq.b, -0.5226, 0.5226);
  float3 rgb = YIQtoRGB * yiq;
  float A = (rgb.r < 0.5 ? (2.0 * rgb.r * warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - warmFilter.r)));
  float B = (rgb.g < 0.5 ? (2.0 * rgb.g * warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - warmFilter.g)));
  float C =  (rgb.b < 0.5 ? (2.0 * rgb.b * warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - warmFilter.b)));
  float3 processed = float3(A,B,C);
  return mix(rgb, processed, temperature);
}

float4 adjustSourceColor(float4 sourceColor, device const float& saturation, device const float& contrast, device const float& brightness, device const float& temperature, device const float& alpha) {
  float3 adjustColor = sourceColor.rgb;
  
  // 饱和度 [0.0, 2.0]
  float3 kRec709Luma = float3(0.2126, 0.7152, 0.0722); // 把rgba转成亮度值
  float gray = dot(adjustColor, kRec709Luma);
  adjustColor = mix(float3(gray, gray, gray), adjustColor, saturation);
  
  // 对比度[0.5, 1.5]
  adjustColor = mix(float3(0.5, 0.5, 0.5), adjustColor, contrast);
  
  // 亮度[0.5, 1.5]
  adjustColor = mix(float3(0.0, 0.0, 0.0), adjustColor, brightness);
  
  // 色温[-1.0, 1.0]
  adjustColor = colorTemperature(adjustColor, temperature);
  
  return float4(adjustColor[0], adjustColor[1], adjustColor[2], sourceColor[3] * alpha);
}

kernel void baseFilterKernel(texture2d<float, access::read> srcTexture  [[texture(0)]],
                             texture2d<float, access::write> dstTexture [[texture(1)]],
                             device const float& saturation [[ buffer(0) ]],
                             device const float& contrast [[ buffer(1) ]],
                             device const float& brightness [[ buffer(2) ]],
                             device const float& temperature [[ buffer(3) ]],
                             device const float& alpha [[ buffer(4) ]],
                             uint2 grid [[thread_position_in_grid]]) {
  float4 sourceColor = srcTexture.read(grid);
  dstTexture.write(adjustSourceColor(sourceColor, saturation, contrast, brightness, temperature, alpha), grid); // 写回对应纹理
}


kernel void adjust_single_saturation(texture2d<float, access::read>input [[texture(0)]], texture2d<float, access::write>output [[texture(1)]], constant float &saturationFactor [[buffer(0)]], uint2 gid [[thread_position_in_grid]] )
{
  float4 inColor = input.read(gid);
  // 转化为灰度
  float value = dot(inColor.rgb, float3(0.299, 0.587, 0.114));
  float4 grayColor(value, value, value, 1.0);
  float4 outColor = mix(grayColor, inColor, saturationFactor);
  output.write(outColor, gid);
}


// https://www.coderzhou.com/2019/02/21/Metal%E5%AD%A6%E4%B9%A0(%E4%B8%89)%EF%BC%9A%E5%AE%9E%E6%88%98%E4%B9%8BLUT%E6%BB%A4%E9%95%9C%E5%8F%8A%E9%A5%B1%E5%92%8C%E5%BA%A6%E6%A8%A1%E7%B3%8A%E5%BA%A6%E8%B0%83%E8%8A%82/
kernel void lookUpTableShader(texture2d<float, access::read> inputTexture [[texture(0)]], texture2d<float, access::write> outputTexture [[texture(1)]], texture2d<float, access::sample> lutTexture [[texture(2)]], uint2 gid [[thread_position_in_grid]])
{
  // 正常的纹理颜色
  float4 sourceColor = inputTexture.read(gid);
  float blueColor = textureColor.b * 63.0; // 蓝色部分[0, 63] 共64种
  
  float2 quad1; // 第一个正方形的位置, 假如blueColor=22.5，则y=22/8=2，x=22-8*2=6，即是第2行，第6个正方形；（因为y是纵坐标）
  quad1.y = floor(floor(blueColor) * 0.125);
  quad1.x = floor(blueColor) - (quad1.y * 8.0);
  
  float2 quad2; // 第二个正方形的位置，同上。注意x、y坐标的计算，还有这里用int值也可以，但是为了效率使用float
  quad2.y = floor(ceil(blueColor) * 0.125);
  quad2.x = ceil(blueColor) - (quad2.y * 8.0);
  
  float2 texPos1; // 计算颜色(r,b,g)在第一个正方形中对应位置
  texPos1.x = ((quad1.x * 64) +  textureColor.r*63 + 0.5)/512.0;
  texPos1.y = ((quad1.y * 64) +  textureColor.g*63 + 0.5)/512.0;
  
  
  float2 texPos2; // 同上
  texPos2.x = ((quad2.x * 64) +  textureColor.r*63 + 0.5)/512.0;
  texPos2.y = ((quad2.y * 64) +  textureColor.g*63 + 0.5)/512.0;
  
  float4 newColor1 = lookupTableTexture.sample(textureSampler, texPos1); // 正方形1的颜色值
  float4 newColor2 = lookupTableTexture.sample(textureSampler, texPos2); // 正方形2的颜色值
  
  float4 newColor = mix(newColor1, newColor2, fract(blueColor)); // 根据小数点的部分进行mix
  float4 resultColor = float4(newColor.rgb, newColor.a * sourceColor.a);
  outputTexture.write(resultColor, gid);
}

