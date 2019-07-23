//
//  DrawImageViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/23.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "DrawImageViewController.h"

#import "MetalBaseView.h"

@interface DrawImageViewController ()

@end

@implementation DrawImageViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  MetalBaseView *metalView = [[MetalBaseView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:metalView];
}

@end
