//
//  CustomCameraViewController.m
//
//  Created by Rock on 2018/9/28.
//  Copyright © 2018 Yiqux. All rights reserved.
//

#import "CustomCameraViewController.h"

#import "YiquxLogic.h"
#import "YiquxCameraManager.h"
#import "YiquxCameraPreviewView.h"
#import "BaseSharedObject.h"

#ifdef YIQUX_OLD_UIINFO
#import "UIButton+Yiqux.h"
#import "UIImageView+Yiqux.h"
#endif

static NSString * const kCameraFlashModeKey = @"custom_camera_flash_mode_key";

@interface CustomCameraViewController () <YiquxViewControllerDelegate,YiquxCameraManagerDelegate>

@property(nonatomic, strong) YiquxCameraManager *cameraManager;
@property(nonatomic, strong) YiquxCameraPreviewView *previewView;
@property(nonatomic, strong) UIButton *flashButton;

@end

@implementation CustomCameraViewController {
#ifdef YIQUX_OLD_UIINFO
  UIInfo *_bgColorUI;
  UIInfo *_cancelBtnUI;
  UIInfo *_cameraSwitchBtnUI;
  UIInfo *_previewAreaUI;
  UIInfo *_takeBtnUI;
  UIInfo *_lightOffUI;
  UIInfo *_lightOnUI;
  UIInfo *_lightAutoUI;
#endif
}

- (void)viewDidLoad {
  [super viewDidLoad];

#ifdef YIQUX_OLD_UIINFO
  [self decodeUI];

  [self drawBgView];

  [self drawContentView];

  [self drawButtonsView];
#endif
  
  [self implementParentClassProperty];
}

- (void)implementParentClassProperty {
  self.autoGetBannerAD = NO;
  self.bannerADUpperCorner = YES;
  self.bannerADCornerHeight = 0;
  self.subVCDelegate = self;
}

#pragma mark - UI

#ifdef YIQUX_OLD_UIINFO

- (void)decodeUI {
  BOOL useX = [UIInfo isUseXInsteadOfXS];
  
  [UIInfo setUseXInsteadOfXS:NO];
  
  NSDictionary *resource = [[BaseSharedObject instance] uiResources:@"yiqux-camera"];

  _bgColorUI = [UIInfo infoWithData:resource prefix:@"bg"];
  _cancelBtnUI = [UIInfo infoWithData:resource prefix:@"camera-cancel"];
  _cameraSwitchBtnUI = [UIInfo infoWithData:resource prefix:@"camera-change"];
  _previewAreaUI = [UIInfo infoWithData:resource prefix:@"camera-photo-bg"];
  _takeBtnUI = [UIInfo infoWithData:resource prefix:@"camera-camera"];
  
  if (![UIDeviceHardware isPad]) {
    _lightOffUI = [UIInfo infoWithData:resource prefix:@"camera-light-off"];
    _lightOnUI = [UIInfo infoWithData:resource prefix:@"camera-light-on"];
    _lightAutoUI = [UIInfo infoWithData:resource prefix:@"camera-light"];
  }
  
  [UIInfo setUseXInsteadOfXS:useX];
}

- (void)drawBgView {
  self.view.backgroundColor = _bgColorUI.color;
}

- (void)drawContentView {
  [self cameraManager];

  self.cameraManager.previewSize = _previewAreaUI.imageArea.size;
}

- (void)drawButtonsView {
  _flashButton = [UIButton buttonWithBGImagePrefix:_lightAutoUI
                                         addToView:self.view
                                            target:self
                                            action:@selector(onLight)];
  [self adjustCameraFlashMode];

  [UIButton buttonWithBGImagePrefix:_cameraSwitchBtnUI
                          addToView:self.view
                             target:self
                             action:@selector(onSwicthCamera)];

  [UIButton buttonWithBGImagePrefix:_takeBtnUI
                          addToView:self.view
                             target:self
                             action:@selector(onTake)];

  [UIButton buttonWithBGImagePrefix:_cancelBtnUI
                          addToView:self.view
                             target:self
                             action:@selector(onClickBack)];
}

#endif

#pragma mark - Lazy Methods

- (YiquxCameraManager *)cameraManager {
  if (!_cameraManager) {
    _cameraManager = [[YiquxCameraManager alloc] init];
    _cameraManager.delegate = self;
    _cameraManager.flashMode = [[NSUserDefaults standardUserDefaults] integerForKey:kCameraFlashModeKey];

    if ([_cameraManager setupSessionWithCameraType:YQCameraTypePhoto]) {
      [self.previewView setSession:_cameraManager.captureSession];
      [_cameraManager startSession];

      // 更改视频显示方向
      AVCaptureConnection *previewLayerConnection = _previewView.connection;
      if ([previewLayerConnection isVideoOrientationSupported]) {
        [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
      }
    }
  }
  
  return _cameraManager;
}

- (YiquxCameraPreviewView *)previewView {
#ifdef YIQUX_OLD_UIINFO
  if (!_previewView) {
    _previewView = [[YiquxCameraPreviewView alloc] initWithFrame:_previewAreaUI.imageArea];
    _previewView.tapToFocusEnabled = NO;
    _previewView.tapToExposeEnabled = NO;
//    _previewView.delegate = self;
    [self.view addSubview:_previewView];
  }
#endif
  return _previewView;
}

#pragma mark - Button Action

- (void)onLight {
  NSInteger flashMode = [[NSUserDefaults standardUserDefaults] integerForKey:kCameraFlashModeKey];
  flashMode ++;
  if (flashMode > AVCaptureFlashModeAuto) {
    flashMode = 0;
  }
  [[NSUserDefaults standardUserDefaults] setInteger:flashMode forKey:kCameraFlashModeKey];
  [[NSUserDefaults standardUserDefaults] synchronize];

  [self adjustCameraFlashMode];
}

- (void)onSwicthCamera {
  [UIView transitionWithView:_previewView
                    duration:0.3
                     options:UIViewAnimationOptionTransitionFlipFromRight
                  animations:^{
                    [self.cameraManager switchCameras];
                    [self adjustCameraFlashMode];
                  } completion:^(BOOL finished) {
                  }];
}

- (void)onTake {
  [_cameraManager captureStillImage:^(UIImage *stillImage) {
    if (stillImage) {
      if ([self.delegate respondsToSelector:@selector(CustomCameraViewControllerDidTakePhoto:)]) {
        [self.delegate CustomCameraViewControllerDidTakePhoto:stillImage];
      }

      [self onClickBack];
    }
  }];
}

- (void)onClickBack {
  if ([YiquxNavigator sharedInstance].topViewController == self) {
    [YiquxNavigator popViewControllerAnimated:YES];
  } else if (self.presentingViewController) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

#pragma mark - Private Methods

- (void)adjustCameraFlashMode {
  self.flashButton.hidden = !self.cameraManager.cameraHasFlash;

  NSInteger flashMode = [[NSUserDefaults standardUserDefaults] integerForKey:kCameraFlashModeKey];
  self.cameraManager.flashMode = flashMode;

#ifdef YIQUX_OLD_UIINFO
  if (AVCaptureFlashModeOff == flashMode) {
    [_flashButton setBackgroundImage:[UIImage imageNamed:_lightOffUI.imageName]
                            forState:UIControlStateNormal];
  } else if (AVCaptureFlashModeOn == flashMode) {
    [_flashButton setBackgroundImage:[UIImage imageNamed:_lightOnUI.imageName]
                            forState:UIControlStateNormal];
  } else if (AVCaptureFlashModeAuto == flashMode) {
    [_flashButton setBackgroundImage:[UIImage imageNamed:_lightAutoUI.imageName]
                            forState:UIControlStateNormal];
  } else {
    YiquxLogFatal(@"camera flash mode not has this type");
  }
#endif
}

@end
