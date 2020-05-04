//
//  ViewController.m
//  TransformDemo
//
//  Created by Rock on 2018/9/10.
//  Copyright © 2018年 Yiqux. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic, assign) CGFloat width;
@property(nonatomic, assign) CGFloat height;

@property(nonatomic, strong) UIImageView *subView;

@property(nonatomic, assign) NSInteger index;

@property(nonatomic, strong) UIImageView *bgImageView;
@property(nonatomic, strong) UIImageView *subImageView;


@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];

  CGSize screenSize = [UIScreen mainScreen].bounds.size;

  self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"1.jpg"]];
  self.bgImageView.layer.anchorPoint = CGPointZero;
  self.bgImageView.frame = CGRectMake(0, 0, screenSize.width/2.0, screenSize.height/2.0);
  self.bgImageView.center = self.view.center;
  [self.view addSubview:self.bgImageView];


  self.subImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"2.jpg"]];
  CGFloat itemWH = screenSize.width / 5.0;
  self.subImageView.frame = CGRectMake(itemWH/2.0, itemWH/2.0, itemWH, itemWH);
  [self.bgImageView addSubview:self.subImageView];

  CGRect leftRect = CGRectMake(0, screenSize.height - 60, screenSize.width/2.0, 50);
  CGRect rightRect = CGRectMake(screenSize.width/2.0, screenSize.height - 60, screenSize.width/2.0, 50);
  UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  [leftBtn setTitle:@"Left" forState:UIControlStateNormal];
  leftBtn.frame = leftRect;
  [leftBtn addTarget:self action:@selector(onLeft) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:leftBtn];

  UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  [rightBtn setTitle:@"Right" forState:UIControlStateNormal];
  rightBtn.frame = rightRect;
  [rightBtn addTarget:self action:@selector(onRight) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:rightBtn];


  UIButton *testBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  [testBtn setTitle:@"Test" forState:UIControlStateNormal];
  testBtn.frame = CGRectOffset(rightRect, 0, -50);
  [testBtn addTarget:self action:@selector(onTest) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:testBtn];
}

- (void)onTest {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGFloat itemWH = screenSize.width / 5.0;

  CGAffineTransform t = CGAffineTransformMakeTranslation(-itemWH/2.0, -itemWH/2.0);
  self.subImageView.transform = t;
}

- (void)onLeft {
  _index++;
  if (_index > 3) {
    _index = 0;
  }

  [self transform];
}

- (void)onRight {
  _index--;
  if (_index < 0) {
    _index = 0;
  }

  [self transform];
}


/**

 struct CGAffineTransform {
 CGFloat a, b, c, d;
 CGFloat tx, ty;
 };

 [ a,  b,  0 ]
 [ c,  d,  0 ]
 [ tx, ty, 1 ]

 x' =  ax + cy + tx;
 y' =  bx + dy + ty;

 a -> x 方向缩放
 d -> y 方向缩放
 tx-> x 偏移
 ty-> y 偏移
 b, c  对应 旋转

 transform 旋转后 坐标系也随之旋转

 原视频  w : 1920  h : 1080
 CGAffineTransformIdentity  [1, 0, 0, 1, 0, 0]

 home 在 右边 默认 transform  [1, 0, 0, 1, 0, 0]     {1920, 1080}
 home 在 下边                [0, 1, -1, 0, 1080, 0],  {1920, 1080}
 home 在 左边                [-1, 0, 0, -1, 1920, 1080]    {1920, 1080}
 home 在 上边                [0, -1, 1, 0, 0, 1920]  {1920, 1080}
 */

- (void)transform {

  NSInteger degress = _index * 90;
  CGAffineTransform transform = CGAffineTransformIdentity;
  NSLog(@"current degress = %ld", (long)degress);

  switch (degress) {
    case 0:
    {
      transform = CGAffineTransformTranslate(transform, 0, 0);
    }
      break;
    case 90:
    {
      transform = CGAffineTransformTranslate(transform, _height, 0);
    }
      break;
    case 180:
    {
      transform = CGAffineTransformTranslate(transform, _width, _height);
    }
      break;
    case 270:
    {
      transform = CGAffineTransformTranslate(transform, 0, _width);
    }
      break;

    default:
      NSLog(@"--------------------");
      break;
  }
  transform = CGAffineTransformRotate(transform, degress / 180.0 * M_PI);

  self.bgImageView.transform = transform;
}

/*

 dx, dy, dz 相对xyz 轴平移的距离

 | 1     0     0    dx |
 | 0     1     0    dy |
 | 0     0     1    dz |
 | 0     0     0     1 |


 Sx, Sy, Sz 缩放的大小

 | Sx    0     0     0 |
 | 0     Sy    0     0 |
 | 0     0     Sz    0 |
 | 0     0     0     1 |



 绕 x轴旋转

 | 1     0     0     0 |
 | 0    cos  -sin    0 |
 | 0    sin   cos    0 |
 | 0     0     0     1 |

 绕 y轴旋转
 | cos   0    sin    0 |
 | 0     1     0     0 |
 | -sin  0    cos    0 |
 | 0     0     0     1 |

 绕 z轴旋转
 | cos  -sin   0     0 |
 | sin  cos    0     0 |
 | 0     0     1     0 |
 | 0     0     0     1 |


 */




@end
