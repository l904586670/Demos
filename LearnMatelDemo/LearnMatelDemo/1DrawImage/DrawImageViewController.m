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
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  CGRect frame = CGRectMake(0, posY, screenSize.width, screenSize.height);
  
  MetalBaseView *metalView = [[MetalBaseView alloc] initWithFrame:frame];
  [self.view addSubview:metalView];
}

@end
