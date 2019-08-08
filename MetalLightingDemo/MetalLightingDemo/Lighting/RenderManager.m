//
//  RenderManager.m
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "RenderManager.h"

@implementation RenderManager

+ (instancetype)instance {
  static RenderManager *manager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    manager = [[RenderManager alloc] init];
  });
  return manager;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    
    _deivce = MTLCreateSystemDefaultDevice();
    if (!_deivce) {
      NSAssert(NO, @"initialize device fail. don't support metal");
    }
    _commandQueue = [_deivce newCommandQueue];
    _colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    
    _library = [_deivce newDefaultLibrary];
  }
  return self;
}

@end
