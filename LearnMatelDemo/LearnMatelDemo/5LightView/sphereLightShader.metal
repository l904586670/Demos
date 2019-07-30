//
//  sphereLightShader.metal
//  LearnMatelDemo
//
//  Created by User on 2019/7/29.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

/**
 step : 递加递减函数
 smootherstep : 平滑过渡函数
 abs : 绝对值
 fmod : 对浮点数取模(求余)
 
 fract : 返回一个值得小数部分
 dot : 返回两个向量的标量积
 pow(x,y) : 计算x的y次方
 */

float distToCircle(float2 point, float2 center, float radius)
{
  return length(point - center) - radius;
}

// 返回一个随机数[0 ~ 1)
float random(float2 p)
{
  return fract(sin(dot(p, float2(15.79, 81.93)) * 45678.9123));
}


// 将双线性内插的网格,并返回一个平滑值
float noise(float2 p)
{
  float2 i = floor(p);
  float2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float bottom = mix(random(i + float2(0)), random(i + float2(1.0, 0.0)), f.x);
  float top = mix(random(i + float2(0.0, 1.0)), random(i + float2(1)), f.x);
  float t = mix(bottom, top, f.y);
  return t;
}

float fbm(float2 uv)
{
  float sum = 0;
  float amp = 0.7;
  for(int i = 0; i < 4; ++i)
  {
    sum += noise(uv) * amp;
    uv += uv * 1.2;
    amp *= 0.4;
  }
  return sum;
}

kernel void lightCompute (texture2d<float, access::write> output [[texture(0)]],
                          constant float &timer [[buffer(0)]],
                          uint2 gid [[thread_position_in_grid]])
{
  uint width = output.get_width();
  uint height = output.get_height();
  
  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  
  float radius = 0.5; // 球体半径
  float distance = distToCircle(uv, float2(0), radius);
  
  // 为了找到球体上的任何点，我们需要球体方程 (x - x0)*(x - x0) + (y - y0)*(y - y0) + (z - z0) * (z - z0) = r * r;
  // 圆心 x0，y0和z0都是0, 求z的值.
  float planet = float(sqrt(radius * radius - uv.x * uv.x - uv.y * uv.y));  // planet 球体到圆心的z值
  //为了在我们的场景中有灯光，我们需要计算normal每个坐标。法线向量在表面上垂直，向我们显示表面在每个坐标处“指向”的位置。
  float3 normal = normalize(float3(uv.x, uv.y, planet)); // 归一化 计算颜色法线
  
  // 创建一个光源, 位置为 :
  float3 source = normalize(float3(cos(timer), sin(timer), 1));
  // 朗伯（漫射）光的基本光模型，我们需要将法线与标准化光源相乘
  float light = dot(normal, source);  // dot 向量的标量积
  output.write(distance < 0 ? float4(float3(light), 1) : float4(0), gid);

}


kernel void noseCompute(texture2d<float, access::write> output [[texture(0)]],
                          constant float &timer [[buffer(0)]],
                          uint2 gid [[thread_position_in_grid]])
{
  uint width = output.get_width();
  uint height = output.get_height();
  
  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  
  float radius = 0.5; // 球体半径
  float distance = distToCircle(uv, float2(0), radius);
  
  uv = fmod(uv + float2(timer * 0.2, 0), float2(width, height));
  float t = fbm( uv * 3 );
  output.write(distance < 0 ? float4(float3(t), 1) : float4(0), gid);
}


// texture2d<float, access::write> 写操作, texture2d<float, access::read> 读操作
// texture2d<float, access::sample> 纹理采样器
kernel void textureCompute(texture2d<float, access::write> output [[texture(0)]],
                           texture2d<float, access::sample> input [[texture(1)]],
                           constant float &timer [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]])
{
  uint width = output.get_width();
  uint height = output.get_height();
  
  // 把纹理等比放大到输出大小
//  float2 scale = float2(gid) / float2(width, height);
//  uint2 scaleGid = uint2(scale * float2(input.get_width(), input.get_height()));
//  float4 color = input.read(scaleGid);
//  output.write(color, gid);

  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;  // 找到中心点
  float radius = 0.5;
  float distance = length(uv) - radius;

//  uv = fmod(float2(gid) + float2(timer * 100, 0), float2(input.get_width(), input.get_height()));
//  float4 color = input.read(uint2(uv));
//  output.write(distance < 0 ? color : float4(0), gid);
  
  uv = uv * 2;
  radius = 1;
  constexpr sampler textureSampler(coord::normalized,
                                   address::repeat,
                                   min_filter::linear,
                                   mag_filter::linear,
                                   mip_filter::linear );
  float3 norm = float3(uv, sqrt(1.0 - dot(uv, uv)));
  float pi = 3.14;
  float s = atan2( norm.z, norm.x ) / (2 * pi);
  float t = asin( norm.y ) / (2 * pi);
  t += 0.5;
  float4 color = input.sample(textureSampler, float2(s + timer * 0.1, t));
  output.write(distance < 0 ? color : float4(0), gid);
}