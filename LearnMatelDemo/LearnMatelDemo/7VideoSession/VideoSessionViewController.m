//
//  VideoSessionViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/30.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "VideoSessionViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "UIViewController+Utils.h"

@interface VideoSessionViewController () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;

@end

@implementation VideoSessionViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self configureMetal];
  
}

#pragma mark - Metal

- (void)configureMetal {
  _mtkView = [[MTKView alloc] initWithFrame:self.contentRect device:MTLCreateSystemDefaultDevice()];
  _mtkView.delegate = self;
  _mtkView.framebufferOnly = NO; // 默认drawable texture 只读, 设为可读写
  [self.view addSubview:_mtkView];
  
  self.commandQueue = [self.mtkView.device newCommandQueue];
  CVMetalTextureCacheCreate(NULL, NULL, self.mtkView.device, NULL, &_textureCache);
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  
}

@end
