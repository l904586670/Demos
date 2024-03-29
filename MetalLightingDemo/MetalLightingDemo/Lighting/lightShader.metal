//
//  lightShader.metal
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct VertexIn {
  float4 position [[ attribute(0) ]];
};

vertex float4 vertex_main(const VertexIn vertexIn [[ stage_in ]],
                          constant Uniforms &uniforms [[ buffer(1) ]])
{
  float4 position = uniforms.projectionMatrix * uniforms.viewMatrix
  * uniforms.modelMatrix * vertexIn.position;
  return position;
}

fragment float4 fragment_main() {
  return float4(0, 0, 1, 1);
}

