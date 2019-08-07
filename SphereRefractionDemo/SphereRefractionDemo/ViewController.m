//
//  ViewController.m
//  SphereRefractionDemo
//
//  Created by User on 2019/8/7.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "SphereRenderView.h"

@interface ViewController ()

@property (nonatomic, strong) SphereRenderView *renderView;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  
  SphereRenderView *renderView = [[SphereRenderView alloc] initWithFrame:self.view.bounds];
  _renderView = renderView;
  [self.view addSubview:renderView];
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGRect frame = CGRectMake(10, screenSize.height - 60, screenSize.width - 20, 40);
  UISlider *radiusSlider = [self sliderWithFrame:frame];
  radiusSlider.tag = 0;
  radiusSlider.value = 0.3;
  frame = CGRectOffset(frame, 0, -CGRectGetHeight(frame));
  UISlider *refractiveSlider = [self sliderWithFrame:frame];
  refractiveSlider.tag = 1;
  refractiveSlider.value = 0.71;
}

- (UISlider *)sliderWithFrame:(CGRect)frame {
  UISlider *slider = [[UISlider alloc] initWithFrame:frame];
  [self.view addSubview:slider];
  [slider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
  return slider;
}

- (void)onSliderValueChange:(UISlider *)sender {
  if (sender.tag == 0) {
    _renderView.radius = sender.value;
  } else {
    _renderView.refractiveIndex = sender.value;
  }
}

@end
