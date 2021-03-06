//
//  ViewController.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/20.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

typedef NS_ENUM(NSInteger, MetalDemoType) {
  MetalDemoTypeDrawTriangle = 0,
  MetalDemoTypeSimpleImage,
  MetalDemoType3D,
  MetalDemoTypeKernel,
  MetalDemoTypeMagic,
  MetalDemoTypeSphereLight,
  MetalDemoTypeTripleBuffer,
  MetalDemoTypeVideoSession,
  MetalDemoTypeShadow,
  MetalDemoTypeRayTracing,
  MetalDemoTypeRaymarching,
  
  MetalDemoTypeCount,
};

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
}

#pragma mark - UI

- (void)setupUI {
  self.title = @"MetalDemo";
  
  _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  _tableView.dataSource = self;
  _tableView.delegate = self;
  _tableView.rowHeight = 70.0;
  
  [self.view addSubview:_tableView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return MetalDemoTypeCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  
  cell.textLabel.text = [self titleWithType:indexPath.row];
  
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UIViewController *vc = [[NSClassFromString([self classNameWithType:indexPath.row]) alloc] init];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private Methods

- (NSString *)titleWithType:(MetalDemoType)type {
  NSArray *titles = @[
                      @"画三角形",
                      @"绘制图片",
                      @"绘制3d空间",
                      @"日全食",
                      @"特效",
                      @"球体灯光",
                      @"三重缓冲",
                      @"渲染视频流",
                      @"灯光和阴影",
                      @"Raymarching",
                      @"光线追踪"
                      ];
  
  return titles[type];
}

- (NSString *)classNameWithType:(MetalDemoType)type {
  NSArray *classes = @[
                      @"DrawTriangleViewController",
                      @"DrawImageViewController",
                      @"ThirdDimensionalViewController",
                      @"KernelShaderViewController",
                      @"MagicViewController",
                      @"SphereLightViewController",
                      @"TripleBufferViewController",
                      @"VideoSessionViewController",
                      @"LightAndShadowViewController",
                      @"RaymarchingViewController",
                      @"RayTracingViewController"
                      
                      ];
  
  return classes[type];
}

@end
