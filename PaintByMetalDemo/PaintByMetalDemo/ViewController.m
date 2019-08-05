//
//  ViewController.m
//  PaintByMetalDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "PaintingViewController.h"
#import "EraseViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
}

#pragma mark - UI

- (void)setupUI {
  self.title = @"绘图demo";
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGRect frame = CGRectMake(10, screenSize.height / 2.0 - 50, screenSize.width - 20, 50);

  [self btnWithFrame:frame
               title:@"画板"
              action:@selector(onPaintButtonTouch)];
  frame = CGRectOffset(frame, 0, 50);
  [self btnWithFrame:frame
               title:@"涂抹"
              action:@selector(onEarseButtonTouch)];
}

- (UIButton *)btnWithFrame:(CGRect)frame title:(NSString *)title action:(SEL)action {
  UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  [nextBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [nextBtn setTitle:title forState:UIControlStateNormal];
  [nextBtn addTarget:self
              action:action
    forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:nextBtn];
  nextBtn.frame = frame;
  return nextBtn;
}

#pragma mark - Button Action

- (void)onPaintButtonTouch {
  PaintingViewController *paintVC = [[PaintingViewController alloc] init];
  [self.navigationController pushViewController:paintVC animated:YES];
}

- (void)onEarseButtonTouch {
  EraseViewController *paintVC = [[EraseViewController alloc] init];
  [self.navigationController pushViewController:paintVC animated:YES];
}

@end
