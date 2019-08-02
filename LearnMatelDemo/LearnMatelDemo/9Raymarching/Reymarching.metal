//
//  Reymarching.metal
//  LearnMatelDemo
//
//  Created by User on 2019/8/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// 光线结构体, 原点 和 朝向
struct Ray {
  float3 origin;
  float3 direction;
  
  Ray(float3 o, float3 d) {
    origin = o;
    direction = d;
  }
};

// 球体, 中心 和 半径
struct Sphere {
  float3 center;
  float radius;
  Sphere(float3 c, float r) {
    center = c;
    radius = r;
  }
};

// 光线到球体表面的距离
float distToSphere(Ray ray, Sphere s) {
  return length(ray.origin - s.center) - s.radius;
}

float distP(float2 point, float2 center, float radius)
{
  return length(point - center) - radius;
}


kernel void reymarchShader(texture2d<float,access::write> output [[texture(0)]], constant float &timer [[buffer(0)]], uint2 gid [[thread_position_in_grid]] )
{
  int width = output.get_width();
  int height = output.get_height();

  float2 uv = float2(gid) / float2(width, height);
  uv = uv * 2.0 - 1.0;
  
  Sphere s = Sphere(float3(0.), 1.);
  Ray ray = Ray(float3(0., 0., -3.), normalize(float3(uv, 1.0)));
  float3 col = float3(0.);
  for (int i=0.; i<100.; i++) {
    float dist = distToSphere(ray, s);
    if (dist < 0.001) {
      col = float3(1.);
      break;
    }
    ray.origin += ray.direction * dist;
  }
  output.write(float4(col, 1.), gid);

}
