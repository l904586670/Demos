//
//  Model.m
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "Model.h"

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>


#import "RenderManager.h"

static MDLVertexDescriptor *defaultVertexDescriptor;

@interface Model ()

@end

@implementation Model

- (instancetype)initWithName:(NSString *)name {
  self = [super init];
  if (self) {
    defaultVertexDescriptor = [MDLVertexDescriptor new];
    defaultVertexDescriptor.attributes[0] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition format:MDLVertexFormatFloat3 offset:0 bufferIndex:0];
    defaultVertexDescriptor.layouts[0] = [[MDLVertexBufferLayout alloc] initWithStride:12];
    
    NSURL *assetUrl = [[NSBundle mainBundle] URLForResource:name withExtension:@"obj"];
    id<MTLDevice> device = [RenderManager instance].deivce;
    MTKMeshBufferAllocator *allocator = [[MTKMeshBufferAllocator alloc] initWithDevice:device];
    MDLAsset *asset = [[MDLAsset alloc] initWithURL:assetUrl vertexDescriptor:defaultVertexDescriptor bufferAllocator:allocator];
    
    MDLMesh *mdlMesh = (MDLMesh *)[asset objectAtIndex:0];
    NSError *error = nil;
    MTKMesh *mesh = [[MTKMesh alloc] initWithMesh:mdlMesh device:device error:&error];
    self.mesh = mesh;
    if (error) {
      NSAssert(NO, @"creat MTKMesh error : %@", error.localizedDescription);
    }
    self.vertexBuffer = mesh.vertexBuffers[0].buffer;

    NSMutableArray<MDLSubmesh*> *submeshes = [mdlMesh submeshes];
    if (!submeshes) {
      self.submeshes = @[];
    } else {
      NSMutableArray <Submesh *>*submesheItems = [NSMutableArray array];
      [submeshes enumerateObjectsUsingBlock:^(MDLSubmesh * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Submesh *submesh = [[Submesh alloc] initWith:mesh.submeshes[idx] mdlSubmesh:obj];
        [submesheItems addObject:submesh];
      }];
      self.submeshes = submesheItems;
    }
    
    self.pipelineState = [self buildPipelineStateWith:mdlMesh.vertexDescriptor];
  }
  return self;
}

- (id<MTLRenderPipelineState>)buildPipelineStateWith:(MDLVertexDescriptor *)vertexDescriptor {
  id<MTLLibrary> library = [RenderManager instance].library;
  id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
  id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
  
  MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineDescriptor.vertexFunction = vertexFunction;
  pipelineDescriptor.fragmentFunction = fragmentFunction;
  pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor);
  pipelineDescriptor.colorAttachments[0].pixelFormat = [RenderManager instance].colorPixelFormat;
  
  NSError *error = nil;
  id<MTLRenderPipelineState> renderPipelineState = [[RenderManager instance].deivce newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
  if (error) {
    NSAssert(NO, @"creat render pipeline fail : %@", error.localizedDescription);
  }
  return renderPipelineState;
}


@end
