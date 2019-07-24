//
//  BaseMetalView.h
//  LearnMatelDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseMetalView : UIView

@property (nonatomic, strong, readonly) id<MTLDevice>               device; // GPU
@property (nonatomic, strong, readonly) MTKView                     *mtkView;
@property (nonatomic, assign, readonly) vector_uint2                viewportSize; 
@property (nonatomic, strong, readonly) id<MTLCommandQueue>         commandQueue;
@property (nonatomic, strong, readonly) id <MTLRenderPipelineState> pipelineState;

- (void)render;

@end

NS_ASSUME_NONNULL_END
