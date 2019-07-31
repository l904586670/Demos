//
//  ViewController.m
//  CustomCameraDemo
//
//  Created by User on 2019/7/30.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "AlbumViewController.h"
#import "CameraViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  
  CGFloat halfH = screenSize.height/2.0;

  CGRect frame = CGRectMake(0, halfH - 50, screenSize.width, 50);
  [self buttonWithFrame:frame title:@"相册" action:@selector(onAlbum)];
  
  frame = CGRectOffset(frame, 0, 50);
  [self buttonWithFrame:frame title:@"相机" action:@selector(onCamera)];
}

- (UIButton *)buttonWithFrame:(CGRect)frame
                        title:(NSString *)title
                       action:(SEL)action {
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
  btn.frame = frame;
  
  [self.view addSubview:btn];
  [btn setTitle:title forState:UIControlStateNormal];
  [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  
  [btn addTarget:self
          action:action
forControlEvents:UIControlEventTouchUpInside];
  return btn;
}

- (void)onAlbum {
  AlbumViewController *albumVC = [[AlbumViewController alloc] init];
  [self.navigationController pushViewController:albumVC animated:YES];
}

- (void)onCamera {
  CameraViewController *cameraVC = [[CameraViewController alloc] init];
  [self presentViewController:cameraVC animated:YES completion:nil];
}


@end
