//
//  HomeViewController.m
//  LearnOpenGL
//
//  Created by User on 2019/7/6.
//  Copyright © 2019 Rock. All rights reserved.
//

// https://learnopengl-cn.github.io/
// https://www.jianshu.com/p/750fde1d8b6a

#import "HomeViewController.h"

#import "DrawTriangleViewController.h"

typedef NS_ENUM(NSInteger, DemoType) {
  DemoTypeDrawPicture = 0,
  
  DemoTypeCount,
};

@interface HomeViewController () <UITableViewDataSource,
                                  UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation HomeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
}

- (void)setupUI {
  self.view.backgroundColor = [UIColor whiteColor];
  self.title = @"Demo目录";
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  CGRect frame = CGRectMake(0, posY, screenSize.width, screenSize.height - posY);
  
  _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
  
  _tableView.dataSource = self;
  _tableView.delegate = self;
  _tableView.rowHeight = 70.0;
  [self.view addSubview:_tableView];
  
}

#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return DemoTypeCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * kCellId = @"cellId";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellId];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  
  cell.textLabel.text = [self titleFromType:indexPath.row];
  
  return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UIViewController *vc = [[NSClassFromString([self classStringFromType:indexPath.row]) alloc] init];
  
  vc.title = [self titleFromType:indexPath.row];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private Methods

- (NSString *)classStringFromType:(DemoType)type {
  if (type < 0 || type >= DemoTypeCount) {
    NSAssert(NO, @"数组越界. 添加demo控制器Class类型");
    return nil;
  }
  NSArray <NSString *>*classes = @[
                                   @"DrawTriangleViewController"
                                   ];
  return classes[type];

}

- (NSString *)titleFromType:(DemoType)type {
  
  if (type < 0 || type >= DemoTypeCount) {
    NSAssert(NO, @"数组越界. 添加demo标题类型");
    return nil;
  }
  NSArray <NSString *>*titles = @[
                                  @"绘制三角形和图片"
                                  ];
  return titles[type];
}


@end
