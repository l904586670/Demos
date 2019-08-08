//
//  ViewController.m
//  MetalLightingDemo
//
//  Created by User on 2019/8/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "Renderer.h"

@interface ViewController ()

@property (nonatomic, strong) Renderer *renderer;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  MTKView *metalView = [[MTKView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:metalView];
//  metalView.colorPixelFormat =
  
  _renderer = [[Renderer alloc] initWithMetalView:metalView];
 
  
  // Do any additional setup after loading the view.
}


@end
