//
//  CommonType.h
//  SwiftMetal-01DrawTriangle
//
//  Created by Rock on 2020/7/21.
//  Copyright © 2020 Rock. All rights reserved.
//

#ifndef CommonType_h
#define CommonType_h

#import <simd/simd.h>

/// 坐标 和 点的颜色
typedef struct {
  vector_float4 position;
  vector_float4 color;
} YLZVertex;

typedef struct {
  matrix_float4x4 mvp_matrix; // model view
} Uniforms;



#endif /* CommonType_h */
