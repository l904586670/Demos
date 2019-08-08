//
//  Submesh.h
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Submesh : NSObject

@property (nonatomic, strong) MTKSubmesh *submesh;

- (instancetype)initWith:(MTKSubmesh *)submesh mdlSubmesh:(MDLSubmesh *)mdlSubmesh;

@end

NS_ASSUME_NONNULL_END
