//
//  PaintMetalLayer.m
//  PaintByMetalDemo
//
//  Created by User on 2019/8/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "PaintMetalLayer.h"

@interface PaintMetalLayer ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@end

@implementation PaintMetalLayer

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super init];
  if (self) {
    self.frame = frame;
    [self configureMetal];
    
  }
  return self;
}

#pragma mark - Metal

- (void)configureMetal {
  self.device = MTLCreateSystemDefaultDevice();
  if (!self.device) {
    NSAssert(NO, @"device don't support metal");
  }
  self.device = self.device;
  
  self.commandQueue = [self.device newCommandQueue];
  self.framebufferOnly = YES;
  self.pixelFormat = MTLPixelFormatBGRA8Unorm;
//  self.contentsScale = [UIScreen mainScreen].scale;
}


@end
