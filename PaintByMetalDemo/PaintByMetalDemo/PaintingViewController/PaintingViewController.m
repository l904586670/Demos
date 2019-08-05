//
//  PaintingViewController.m
//  PaintByMetalDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "PaintingViewController.h"

#import "PaintMetalView.h"

@interface PaintingViewController ()

@property (nonatomic, strong) PaintMetalView *paintView;

@end

@implementation PaintingViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
  if (@available(iOS 11.0, *)) {
    safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
  }
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  CGFloat height = screenSize.height - posY - safeAreaInsets.bottom;
  
  CGRect frame = CGRectMake(0, posY, screenSize.width, height);
  
  PaintMetalView *paintView = [[PaintMetalView alloc] initWithFrame:frame];
  [self.view addSubview:paintView];
  _paintView = paintView;

  [self setupUI];
}

- (void)setupUI {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGRect frame = CGRectMake(10, screenSize.height - 100, screenSize.width -20, 40);
  
  UISlider *slider = [[UISlider alloc] initWithFrame:frame];
  [self.view addSubview:slider];
  [slider addTarget:self
             action:@selector(onPaintSizeChange:)
   forControlEvents:UIControlEventValueChanged];
  
  CGRect firstItemRect = CGRectMake(10, screenSize.height - 140, 50, 40);
  NSArray *colorArray = @[@"红色", @"黄色"];
  for (NSInteger i = 0; i < colorArray.count; i++) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectOffset(firstItemRect, i * CGRectGetWidth(firstItemRect), 0);
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn setTitle:colorArray[i] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    btn.tag = i;
    [btn addTarget:self action:@selector(onColorBtnTouch:) forControlEvents:UIControlEventTouchUpInside];
  }

}

#pragma mark - Action

// 最小30.0 最大设为100.0
- (void)onPaintSizeChange:(UISlider *)sender {
  float size = sender.value * (100.0 - 30.0) + 30.0;
  _paintView.brushSize = size;
  
}

- (void)onColorBtnTouch:(UIButton *)sender {
  NSInteger index = sender.tag;
  NSArray *colorArray = @[[UIColor redColor], [UIColor yellowColor]];
  _paintView.brushColor = colorArray[index];
}

@end
