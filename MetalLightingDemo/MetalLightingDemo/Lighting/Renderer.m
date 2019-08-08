//
//  Renderer.m
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "Renderer.h"

#import "Camera.h"
#import "Model.h"
#import "RenderManager.h"

@interface Renderer () <MTKViewDelegate>

@property (nonatomic, strong) Camera *camera;
@property (nonatomic, strong) NSMutableArray <Model *>*models;

@property (nonatomic, strong) id<MTLRenderPipelineState> lightPipelineState;

@end

@implementation Renderer

- (instancetype)initWithMetalView:(MTKView *)mtkView {
  [RenderManager instance].colorPixelFormat = mtkView.colorPixelFormat;
  if (self = [super init]) {
    mtkView.clearColor = MTLClearColorMake(1.0, 1.0, 0.8, 1.0);
    mtkView.delegate = self;
    mtkView.device = [RenderManager instance].deivce;
    [self mtkView:mtkView drawableSizeWillChange:mtkView.bounds.size];
    
    Model *train = [[Model alloc] initWithName:@"train"];
    train.position = simd_make_float3(0, 0, 0);
    train.rotation = simd_make_float3(0, [MathLibrary radiansFromDegrees:45.0], 0);
    [self.models addObject:train];
    
    Uniforms uniforms;
    uniforms.modelMatrix = matrix_identity_float4x4;
    uniforms.projectionMatrix = matrix_identity_float4x4;
    uniforms.viewMatrix = matrix_identity_float4x4;
    self.uniforms = uniforms;
   
  }
  return self;
}


// Camera holds view and projection matrices
- (Camera *)camera {
  if (!_camera) {
    _camera = [[Camera alloc] init];
    _camera.position = simd_make_float3(0, 0.5, -3.0);
  }
  return _camera;
}

- (NSMutableArray<Model *> *)models {
  if (!_models) {
    _models = [NSMutableArray array];
  }
  return _models;
}

// Debug drawing of lights
- (id<MTLRenderPipelineState>)lightPipelineState {
  if (!_lightPipelineState) {
    _lightPipelineState = [self buildLightPipelineState];
  }
  return _lightPipelineState;
}

#pragma mark - Private Methods

- (id<MTLRenderPipelineState>)buildLightPipelineState {
  id<MTLLibrary> library = [[RenderManager instance].deivce newDefaultLibrary];
  
  id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_light"];
  id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_light"];
  
  MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineDescriptor.vertexFunction = vertexFunction;
  pipelineDescriptor.fragmentFunction = fragmentFunction;
  
  pipelineDescriptor.colorAttachments[0].pixelFormat = [RenderManager instance].colorPixelFormat;
  
  pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
  
  NSError *error = nil;
  id<MTLRenderPipelineState> renderPipelineState = [[RenderManager instance].deivce newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
  if (error) {
    NSAssert(NO, @"init render pipeline state error : %@", error.localizedDescription);
    return nil;
  }
  return renderPipelineState;
}

#pragma mark - Public Methods

- (void)zoomUsing:(float)delta sensitivity:(float)sensitivity {
  simd_float3 cameraVector = [MathLibrary upperLeftWithMatrix:self.camera.modelMatrix].columns[2];
  self.camera.position += delta * sensitivity * cameraVector;
}

- (void)rotateUsing:(simd_float2)translation {
  float sensitivity = 0.01;
  
  simd_float4x4 matrix = [MathLibrary matrixWithRotationY:-translation.x * sensitivity];
  
  self.camera.position = simd_mul(self.camera.position, [MathLibrary upperLeftWithMatrix:matrix]);
  float y = atan2f(-self.camera.position.x, -self.camera.position.z);
  float x = self.camera.rotation.x;
  float z = self.camera.rotation.z;
  self.camera.rotation = simd_make_float3(x, y, z);
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  self.camera.aspect = CGRectGetWidth(view.bounds)/ CGRectGetHeight(view.bounds);
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  MTLRenderPassDescriptor *descriptor = view.currentRenderPassDescriptor;
  id<MTLCommandBuffer> commandBuffer = [[RenderManager instance].commandQueue commandBuffer];
  id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
  if (!renderEncoder) {
    return;
  }
  
  _uniforms.projectionMatrix = self.camera.projectionMatrix;
  _uniforms.viewMatrix = self.camera.viewMatrix;
  
  for (Model * model in self.models) {
    _uniforms.modelMatrix = model.modelMatrix;
    [renderEncoder setRenderPipelineState:model.pipelineState];
    [renderEncoder setVertexBuffer:model.vertexBuffer offset:0 atIndex:0];
    
    [renderEncoder setVertexBytes:&_uniforms length:sizeof(Uniforms) atIndex:1];
    
    for (MTKSubmesh *submesh in model.mesh.submeshes) {
      [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:submesh.indexCount indexType:submesh.indexType indexBuffer:submesh.indexBuffer.buffer indexBufferOffset:submesh.indexBuffer.offset];
      
    }
  }

  [renderEncoder endEncoding];
  id<CAMetalDrawable> drawable = view.currentDrawable;
  if (!drawable) {
    return;
  }
  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
}

@end
