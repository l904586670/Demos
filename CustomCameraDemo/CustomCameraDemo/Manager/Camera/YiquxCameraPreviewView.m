//
//  YiquxCameraPreviewView.m
//  SnakeScreenByLink
//
//  Created by Rock on 2018/5/10.
//  Copyright © 2018年 Yiqux. All rights reserved.
//

#import "YiquxCameraPreviewView.h"

#import <AVFoundation/AVFoundation.h>

#define BOX_BOUNDS CGRectMake(0.0f, 0.0f, 150.0f, 150.0f)

// *****************************************************************

@interface YiquxCameraPreviewView ()

@property(strong, nonatomic) UIView *focusBox;
@property(strong, nonatomic) UIView *exposureBox;
@property(strong, nonatomic) NSTimer *timer;
@property(strong, nonatomic) UITapGestureRecognizer *singleTapRecognizer;
@property(strong, nonatomic) UITapGestureRecognizer *doubleTapRecognizer;
@property(strong, nonatomic) UITapGestureRecognizer *doubleDoubleTapRecognizer;

@end

// *****************************************************************

@implementation YiquxCameraPreviewView

+ (Class)layerClass {
  return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureConnection *)connection {
  AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
  return layer.connection;
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setupView];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self setupView];
  }
  return self;
}

- (void)setupView {
  AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
  [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

  _singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];

  _doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
  _doubleTapRecognizer.numberOfTapsRequired = 2;

  _doubleDoubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleDoubleTap:)];
  _doubleDoubleTapRecognizer.numberOfTapsRequired = 2;
  _doubleDoubleTapRecognizer.numberOfTouchesRequired = 2;

  [self addGestureRecognizer:_singleTapRecognizer];
  [self addGestureRecognizer:_doubleTapRecognizer];
  [self addGestureRecognizer:_doubleDoubleTapRecognizer];

  [_singleTapRecognizer requireGestureRecognizerToFail:_doubleTapRecognizer];

  _focusBox = [self viewWithColor:[UIColor colorWithRed:0.102 green:0.636 blue:1.000 alpha:1.000]];
  _exposureBox = [self viewWithColor:[UIColor colorWithRed:1.000 green:0.421 blue:0.054 alpha:1.000]];

  [self addSubview:_focusBox];
  [self addSubview:_exposureBox];
}

- (void)handleSingleTap:(UIGestureRecognizer *)recognizer {
  CGPoint point = [recognizer locationInView:self];
  [self runBoxAnimationOnView:self.focusBox point:point];
  if (self.delegate) {
    [self.delegate tappedToFocusAtPoint:[self captureDevicePointForPoint:point]];
  }
}

- (void)handleDoubleTap:(UIGestureRecognizer *)recognizer {
  CGPoint point = [recognizer locationInView:self];
  [self runBoxAnimationOnView:self.exposureBox point:point];
  if (self.delegate) {
    [self.delegate tappedToExposeAtPoint:[self captureDevicePointForPoint:point]];
  }
}

- (void)handleDoubleDoubleTap:(UIGestureRecognizer *)recognizer {
  [self runResetAnimation];
  if (self.delegate) {
    [self.delegate tappedToResetFocusAndExposure];
  }
}

#pragma mark - Public Methods

- (void)setTapToFocusEnabled:(BOOL)enabled {
  _tapToFocusEnabled = enabled;
  self.singleTapRecognizer.enabled = enabled;
}

- (void)setTapToExposeEnabled:(BOOL)enabled {
  _tapToExposeEnabled = enabled;
  self.doubleTapRecognizer.enabled = enabled;
}

#pragma mark - Private Methods

- (UIView *)viewWithColor:(UIColor *)color {
  UIView *view = [[UIView alloc] initWithFrame:BOX_BOUNDS];
  view.backgroundColor = [UIColor clearColor];
  view.layer.borderColor = color.CGColor;
  view.layer.borderWidth = 5.0f;
  view.hidden = YES;
  
  return view;
}

- (void)runBoxAnimationOnView:(UIView *)view point:(CGPoint)point {
  view.center = point;
  view.hidden = NO;
  
  [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
    view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
  } completion:^(BOOL complete) {
    double delayInSeconds = 0.5f;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      view.hidden = YES;
      view.transform = CGAffineTransformIdentity;
    });
  }];
}

- (void)runResetAnimation {
  if (!self.tapToFocusEnabled && !self.tapToExposeEnabled) {
    return;
  }
  
  AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
  CGPoint centerPoint = [previewLayer pointForCaptureDevicePointOfInterest:CGPointMake(0.5f, 0.5f)];
  
  self.focusBox.center = centerPoint;
  self.exposureBox.center = centerPoint;
  self.exposureBox.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
  self.focusBox.hidden = NO;
  self.exposureBox.hidden = NO;
  
  [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
    self.focusBox.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
    self.exposureBox.layer.transform = CATransform3DMakeScale(0.7, 0.7, 1.0);
  } completion:^(BOOL complete) {
    double delayInSeconds = 0.5f;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      self.focusBox.hidden = YES;
      self.exposureBox.hidden = YES;
      self.focusBox.transform = CGAffineTransformIdentity;
      self.exposureBox.transform = CGAffineTransformIdentity;
    });
  }];
}

- (void)setSession:(AVCaptureSession *)session {
  AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
  [layer setSession:session];
}

- (AVCaptureSession *)session {
  AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
  return layer.session;
}

- (CGPoint)captureDevicePointForPoint:(CGPoint)point {
  AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
  return [layer captureDevicePointOfInterestForPoint:point];
}

@end
