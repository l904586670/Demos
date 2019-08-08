//
//  Model.h
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "BaseNode.h"

#import "Submesh.h"

NS_ASSUME_NONNULL_BEGIN

@interface Model : BaseNode

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) MTKMesh *mesh;
@property (nonatomic, strong) NSArray <Submesh *> *submeshes;

- (instancetype)initWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
