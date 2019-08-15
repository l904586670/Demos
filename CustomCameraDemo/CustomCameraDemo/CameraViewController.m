//
//  CameraViewController.m
//  CustomCameraDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "CameraViewController.h"

#import "YiquxCameraPreviewView.h"
#import "AVCameraManager.h"
#import "AVVideoMotionManager.h"

#import <CoreMotion/CoreMotion.h>

@interface CameraViewController () <YiquxCameraPreviewViewDelegate>

@property (nonatomic, strong) AVCameraManager *baseCamera;

@property (nonatomic, strong) YiquxCameraPreviewView *previewView;

@property (nonatomic, strong) AVVideoMotionManager *motionManager;

@end

@implementation CameraViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self baseCamera];
  
  [self setupUI];
  
  NSLog(@"---");
//  CMMotionManager *m = [[CMMotionManager alloc] init];
  _motionManager = [[AVVideoMotionManager alloc] init];
  NSLog(@"===");
}

- (AVCameraManager *)baseCamera {
  if (!_baseCamera) {
    _baseCamera = [[AVCameraManager alloc] init];
    [self.previewView setSession:_baseCamera.session];
    
    dispatch_async(_baseCamera.sessionQueue, ^{
      [_baseCamera.session startRunning];
    });
    
    // 更改视频显示方向
    AVCaptureConnection *previewLayerConnection = _previewView.connection;
    if ([previewLayerConnection isVideoOrientationSupported]) {
      [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
  }
  return _baseCamera;
}


- (YiquxCameraPreviewView *)previewView {

  if (!_previewView) {
    CGRect frame = [self innerRectWithAspectRatio:CGSizeMake(1, 1) outRect:self.view.bounds];
    _previewView = [[YiquxCameraPreviewView alloc] initWithFrame:frame];
    _previewView.delegate = self;
//    _previewView.tapToFocusEnabled = NO;
//    _previewView.tapToExposeEnabled = NO;
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
  UIButton *btn = [self buttonWithFrame:frame
                  title:nil
                  image:[UIImage imageNamed:@"takePhoto"]
          selectedImage:nil
                 action:nil];
  UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
  [btn addGestureRecognizer:longPress];
  UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCamera)];
  [btn addGestureRecognizer:tapGesture];
  
  // flash
  frame = CGRectMake(30, 100, 40, 40);
  [self buttonWithFrame:frame
                  title:nil
                  image:[UIImage imageNamed:@"flashOff"]
          selectedImage:[UIImage imageNamed:@"flashOn"]
                 action:@selector(onFlash:)];
  
  frame = CGRectMake(screenSize.width - 70, 100, 40, 40);
  [self buttonWithFrame:frame
                  title:nil
                  image:[UIImage imageNamed:@"cameraFlip"]
          selectedImage:nil
                 action:@selector(onSwicthCamera:)];

  frame = CGRectMake(screenSize.width - itemWH, screenSize.height - itemWH -30, 40, 40);
  [self buttonWithFrame:frame
                  title:nil
                  image:[UIImage imageNamed:@"Size"]
          selectedImage:nil
                 action:@selector(onSwicthSize:)];
}

#pragma mark - Button Action

- (void)onCamera {
  [_baseCamera capturePhoto:^(UIImage * _Nullable resultImage, NSData * _Nonnull imgData) {
    
  }];
}

- (void)onLongPress:(UILongPressGestureRecognizer *)longPress {
  if (longPress.state == UIGestureRecognizerStateBegan) {
    [_baseCamera startRecording];
    NSLog(@"start record");
  } else if (longPress.state == UIGestureRecognizerStateEnded) {
    [_baseCamera stopRecording];
    NSLog(@"end record");
  }
}

- (void)onFlash:(UIButton *)sender {
  sender.selected = !sender.selected;
  
  if (sender.isSelected) {
    _baseCamera.flashMode = AVCaptureFlashModeOn;
  } else {
    _baseCamera.flashMode = AVCaptureFlashModeOff;
  }
}

- (void)onSwicthCamera:(UIButton *)sender {
  
  [_baseCamera switchCamera];
}

- (void)onSwicthSize:(UIButton *)sender {
  sender.selected = !sender.selected;
  
  if (sender.isSelected) {
    [_baseCamera changeCaptureMode:AVCaptureModeVideo];
  } else {
    [_baseCamera changeCaptureMode:AVCaptureModePhoto];
  }
}

- (UIButton *)buttonWithFrame:(CGRect)frame
                        title:(NSString *)title
                        image:(UIImage *)image
                selectedImage:(UIImage *)selectedImage
                       action:(SEL)action {
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
  btn.frame = frame;
  
  [self.view addSubview:btn];
  [btn setTitle:title forState:UIControlStateNormal];
  [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [btn setImage:image
       forState:UIControlStateNormal];
  [btn setImage:selectedImage
       forState:UIControlStateSelected];
  
  [btn addTarget:self
          action:action
forControlEvents:UIControlEventTouchUpInside];
  return btn;
}

#pragma mark - YiquxCameraPreviewViewDelegate

/**
 对某点聚焦 (单击触发)
 
 @param point point为转换过坐标系后的point
 */
- (void)tappedToFocusAtPoint:(CGPoint)point {
  [_baseCamera focusAtPoint:point];
}

/**
 对某点曝光 (双击触发)
 
 @param point point为转换过坐标系后的point
 */
- (void)tappedToExposeAtPoint:(CGPoint)point {
  [_baseCamera exposeAtPoint:point];
}

/**
 复原 (双指双击触发)
 */
- (void)tappedToResetFocusAndExposure {
  [_baseCamera resetFocusAndExposureModes];
}


- (CGRect)innerRectWithAspectRatio:(CGSize)aspectRatio outRect:(CGRect)outRect {
  CGFloat factor = aspectRatio.width / aspectRatio.height;
  CGFloat outRectFactor = outRect.size.width / outRect.size.height;
  CGFloat width = 0.0;
  CGFloat height = 0.0;
  CGFloat posX = 0.0;
  CGFloat posY = 0.0;
  if (factor > outRectFactor) {
    // 最大值为宽
    width = CGRectGetWidth(outRect);
    height = width / factor;
    posX = 0.0;
    posY = (CGRectGetHeight(outRect) - height)/2.0;
  } else {
    // 最大值为高
    height = CGRectGetHeight(outRect);
    width = factor * height;
    posY = 0.0;
    posX = (CGRectGetWidth(outRect) - width)/2.0;
  }
  return CGRectMake(posX, posY, width, height);
}

@end
