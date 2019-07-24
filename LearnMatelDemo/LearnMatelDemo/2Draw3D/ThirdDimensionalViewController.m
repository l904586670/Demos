//
//  ThirdDimensionalViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ThirdDimensionalViewController.h"

#import "BaseMetalView.h"

@interface ThirdDimensionalViewController ()

@end

@implementation ThirdDimensionalViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  CGRect frame = CGRectMake(0, posY, screenSize.width, screenSize.height);
  
  BaseMetalView *metalView = [[BaseMetalView alloc] initWithFrame:frame];
  [self.view addSubview:metalView];
}

@end
