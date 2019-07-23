//
//  MetalBaseView.h
//  LearnMatelDemo
//
//  Created by User on 2019/7/23.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalBaseView : UIView

@property (nonatomic, strong, readonly) id<MTLDevice> device;
@property (nonatomic, assign, readonly) vector_uint2 viewportSize;
@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong, readonly) MTKView *mtkView;
@property (nonatomic, strong, readonly) id <MTLRenderPipelineState> pipelineState;

@end

NS_ASSUME_NONNULL_END
