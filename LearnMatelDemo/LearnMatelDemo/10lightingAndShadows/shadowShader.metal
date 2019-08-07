//
//  shadowShader.metal
//  LearnMatelDemo
//
//  Created by User on 2019/8/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// 返回两个有符号距离之间的差
float differenceOp(float d0, float d1) {
  return max(d0, -d1);
}

// 确定给定点是在矩形内部还是外部
float distanceToRect( float2 point, float2 center, float2 size ) {
  point -= center;
  point = abs(point); // 获取当前点到中心点的距离绝对值
  point -= size / 2.; // 减去half Size
  return max(point.x, point.y); // 最大值 大于零 在外面, 小于零在里面
}

// 与场景中任何对象的最近距离
float distanceToScene( float2 point ) {
  // 当前点是否在 center = 0,0 size = {0,45, 0.85}的矩形内
  float d2r1 = distanceToRect( point, float2(0.), float2(0.45, 0.85) );
  float2 mod = point - 0.1 * floor(point / 0.1); // 求余
  float d2r2 = distanceToRect( mod, float2( 0.05 ), float2(0.02, 0.04) );
  float diff = differenceOp(d2r1, d2r2);
  return diff;
}

// 获取实际阴影
float getShadow(float2 point, float2 lightPos) {
//  float2 lightDir = lightPos - point;   // 获取点到光源的方向
//  float dist2light = length(lightDir);  // 获取距离
//  for (float i=0.; i < 300.; i++) {
//    float distAlongRay = dist2light * (i / 300.);
//    float2 currentPoint = point + lightDir * distAlongRay;
//    float d2scene = distanceToScene(currentPoint);
//    if (d2scene <= 0.) { return 0.; }
//  }
//  return 1.;
  
  float2 lightDir = normalize(lightPos - point);
  float dist2light = length(lightDir);
  float distAlongRay = 0.0;
  for (float i=0.0; i < 80.; i++) {
    float2 currentPoint = point + lightDir * distAlongRay;
    float d2scene = distanceToScene(currentPoint);
    if (d2scene <= 0.001) { return 0.0; }
    distAlongRay += d2scene;
    if (distAlongRay > dist2light) { break; }
  }
  return 1.;
}

kernel void shadowCompute(texture2d<float, access::write> output [[texture(0)]],
                           texture2d<float, access::sample> input [[texture(1)]],
                           constant float &timer [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]])
{
  int width = output.get_width();
  int height = output.get_height();
  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  float d2scene = distanceToScene(uv);
  bool i = d2scene < 0.0;
  float4 color = i ? float4( .1, .5, .5, 1. ) : float4( .7, .8, .8, 1. );
  
  // 创建一个可移动的灯光
  float2 lightPos = float2(1.3 * sin(timer), 1.3 * cos(timer));
  float dist2light = length(lightPos - uv);
  color *= max(0.0, 2. - dist2light );
//  output.write(color, gid);
  
  float shadow = getShadow(uv, lightPos);
  shadow = shadow * 0.5 + 0.5;
  color *= shadow;
  output.write(color, gid);
}

