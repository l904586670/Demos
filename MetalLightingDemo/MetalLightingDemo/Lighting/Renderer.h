//
//  Renderer.h
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

#import "Common.h"

NS_ASSUME_NONNULL_BEGIN

@interface Renderer : NSObject

- (instancetype)initWithMetalView:(MTKView *)mtkView;

@property (nonatomic, assign) Uniforms uniforms;

- (void)rotateUsing:(simd_float2)translation;
- (void)zoomUsing:(float)delta sensitivity:(float)sensitivity;

@end

NS_ASSUME_NONNULL_END
