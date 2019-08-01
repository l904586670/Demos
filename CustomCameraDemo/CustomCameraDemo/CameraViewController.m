//
//  CameraViewController.m
//  CustomCameraDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "CameraViewController.h"

#import "DHCameraManager.h"
#import "YiquxCameraPreviewView.h"

@interface CameraViewController ()

@property (nonatomic, strong) DHCameraManager *cameraManager;
@property (nonatomic, strong) YiquxCameraPreviewView *previewView;

@end

@implementation CameraViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self cameraManager];
  
  [self setupUI];
}

- (DHCameraManager *)cameraManager {
  if (!_cameraManager) {
    _cameraManager = [[DHCameraManager alloc] init];
    
    [_cameraManager setupSession];
    [self.previewView setSession:_cameraManager.captureSession];
    [_cameraManager startSession];
    
    // 更改视频显示方向
    AVCaptureConnection *previewLayerConnection = _previewView.connection;
    if ([previewLayerConnection isVideoOrientationSupported]) {
      [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
  }
  return _cameraManager;
}



- (YiquxCameraPreviewView *)previewView {

  if (!_previewView) {
    _previewView = [[YiquxCameraPreviewView alloc] initWithFrame:self.view.bounds];
    _previewView.tapToFocusEnabled = NO;
    _previewView.tapToExposeEnabled = NO;
    //    _previewView.delegate = self;
    [self.view addSubview:_previewView];
  }
  return _previewView;
}

#pragma mark - UI

- (void)setupUI {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGFloat halfW = screenSize.width/2.0;
//  CGFloat halfH = screenSize.height/2.0;
  CGFloat itemWH = 50.0;
  CGRect frame = CGRectMake(halfW - itemWH/2.0, screenSize.height - itemWH -30, itemWH, itemWH);
  UIButton *cameraBtn = [self buttonWithFrame:frame title:nil action:@selector(onCamera)];
  [cameraBtn setImage:[UIImage imageNamed:@"camera-toke"]
             forState:UIControlStateNormal];
}

#pragma mark - Button Action

- (void)onCamera {
  [_cameraManager captureStillImage];
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

@end
