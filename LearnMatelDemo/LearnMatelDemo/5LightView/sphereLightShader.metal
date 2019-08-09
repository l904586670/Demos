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


constant float3 kRec709Luma = float3(0.2126, 0.7152, 0.0722); // 把rgba转成亮度值
// 灰度计算
kernel void grayKernel(texture2d<float, access::write> output [[texture(0)]],
                       texture2d<float, access::sample> input [[texture(1)]],
                       constant float &timer [[buffer(0)]],
                       uint2 gid [[thread_position_in_grid]])
{
 
  uint width = output.get_width();
  uint height = output.get_height();
 
  float2 uv = float2(gid) / float2(width, height);
 
  
  constexpr sampler textureSampler(coord::normalized,
                                   address::repeat,
                                   min_filter::linear,
                                   mag_filter::linear,
                                   mip_filter::linear );

  float4 color = input.sample(textureSampler, uv);
  float gray = dot(color.rgb, kRec709Luma); // 转换成亮度
  output.write(float4(gray, gray, gray, 1.0), gid); // 写回对应纹理
}


// 边缘检测
/*
 Sobel算子的实现需要访问像素周边的8个像素的值，在compute shader中，我们可以通过修改grid的xy坐标进行操作。在拿到位置的坐标后，通过sourceTexture.read读取像素值，分别算出横向和竖向的差别h和v，统一转亮度值。最后求h和v的向量和，再写回纹理中。
 */
constant int sobelStep = 2;
kernel void sobelKernel(texture2d<float, access::write> output [[texture(0)]], texture2d<float, access::read> input [[texture(1)]],  uint2 grid [[thread_position_in_grid]])
{
  /*
   
   行数     9个像素          位置
   上     | * * * |      | 左 中 右 |
   中     | * * * |      | 左 中 右 |
   下     | * * * |      | 左 中 右 |
   
   */
  float4 topLeft = input.read(uint2(grid.x - sobelStep, grid.y - sobelStep)); // 左上
  float4 top = input.read(uint2(grid.x, grid.y - sobelStep)); // 上
  float4 topRight = input.read(uint2(grid.x + sobelStep, grid.y - sobelStep)); // 右上
  float4 centerLeft = input.read(uint2(grid.x - sobelStep, grid.y)); // 中左
  float4 centerRight = input.read(uint2(grid.x + sobelStep, grid.y)); // 中右
  float4 bottomLeft = input.read(uint2(grid.x - sobelStep, grid.y + sobelStep)); // 下左
  float4 bottom = input.read(uint2(grid.x, grid.y + sobelStep)); // 下中
  float4 bottomRight = input.read(uint2(grid.x + sobelStep, grid.y + sobelStep)); // 下右
  
  float4 h = -topLeft - 2.0 * top - topRight + bottomLeft + 2.0 * bottom + bottomRight; // 横方向差别
  float4 v = -bottom - 2.0 * centerLeft - topLeft + bottomRight + 2.0 * centerRight + topRight; // 竖方向差别
  
  float  grayH  = dot(h.rgb, kRec709Luma); // 转换成亮度
  float  grayV  = dot(v.rgb, kRec709Luma); // 转换成亮度
  
  // sqrt(h^2 + v^2)，相当于求点到(h, v)的距离，所以可以用length
  half color = length(half2(grayH, grayV));
  
  output.write(float4(color, color, color, 1.0), grid); // 写回对应纹理
}
