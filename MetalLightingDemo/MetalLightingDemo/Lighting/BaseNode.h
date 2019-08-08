//
//  BaseNode.h
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

#import "MathLibrary.h"

NS_ASSUME_NONNULL_BEGIN

@interface BaseNode : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) simd_float3 position;
@property (nonatomic, assign) simd_float3 rotation;
@property (nonatomic, assign) simd_float3 scale;

@property (nonatomic, assign) simd_float4x4 modelMatrix;

@end

NS_ASSUME_NONNULL_END
