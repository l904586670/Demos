//
//  Submesh.m
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "Submesh.h"

@implementation Submesh

- (instancetype)initWith:(MTKSubmesh *)submesh mdlSubmesh:(MDLSubmesh *)mdlSubmesh {
  self = [super init];
  if (self) {
    self.submesh = submesh;
  }
  return self;
}

@end
