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

float distToScene(Ray r) {
  Sphere s = Sphere(float3(1.), 0.5);
  Ray repeatRay = r;
  repeatRay.origin = fmod(r.origin, 2.0);
  return distToSphere(repeatRay, s);
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
  
  float3 camPos = float3(1000. + sin(timer) + 1., 1000. + cos(timer) + 1., timer);
  // 创建一个射线
  Ray ray = Ray(camPos, normalize(float3(uv, 1.)));
  
  
  float3 col = float3(0.);
  for (int i=0.; i<100.; i++) {
    float dist = distToScene(ray);
    if (dist < 0.001) {
      col = float3(1.);
      break;
    }
    ray.origin += ray.direction * dist;
  }
  float3 posRelativeToCamera = ray.origin - camPos;
  output.write(float4(col * abs((posRelativeToCamera) / 10.0), 1.), gid);
//  output.write(float4(col * abs((ray.origin - 1000.) / 10.0), 1.), gid);
}
