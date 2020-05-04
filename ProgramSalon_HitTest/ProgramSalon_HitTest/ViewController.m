//
//  ViewController.m
//  ProgramSalon_HitTest
//
//  Created by trevor on 6/25/16.
//  Copyright © 2016 yiqux. All rights reserved.
//

#import "ViewController.h"
#import "AView.h"
#import "BView.h"
#import "CView.h"
#import "DView.h"
#import "EView.h"
#import "OverlayView.h"

NSInteger gWidthOffset = 10;
NSInteger gHeightOffset = 20;

NSInteger gLabelWidth = 100;
NSInteger gLabelHeight = 20;


@interface ViewController ()<UIAlertViewDelegate> {
  AView *_viewA;
  BView *_viewB;
  CView *_viewC;
  DView *_viewD;
  EView *_viewE;
  OverlayView *_viewOverlay;
}

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  
  [self addViewA];
  
  [self addViewB];
  
  [self addViewC];
  
  [self addViewD];
  
  [self addViewE];
  
  [self addViewOverlay];
  
  NSLog(@"Log Begin...");
}

- (void)addViewA {
  _viewA = [[AView alloc] initWithFrame:self.view.bounds];
  _viewA.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.2];
  [self.view addSubview:_viewA];
  
  [_viewA addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapViewA:)]];
  
  UILabel *viewName = [[UILabel alloc] initWithFrame:CGRectMake(0, gHeightOffset, gLabelWidth, gLabelHeight)];
  viewName.text = @"View A";
  [_viewA addSubview:viewName];
}

- (void)addViewB {
  _viewB = [[BView alloc] initWithFrame:CGRectMake(gWidthOffset, 4*gHeightOffset, CGRectGetWidth(_viewA.frame)-2*gWidthOffset, 0.4*CGRectGetHeight(_viewA.frame))];
  _viewB.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.4];
  [_viewA addSubview:_viewB];
  
  [_viewB addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapViewB:)]];
  
  UILabel *viewName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, gLabelWidth, gLabelHeight)];
  viewName.text = @"View B";
  [_viewB addSubview:viewName];
}

- (void)addViewC {
  _viewC = [[CView alloc] initWithFrame:CGRectMake(gWidthOffset, gHeightOffset + CGRectGetMaxY(_viewB.frame), CGRectGetWidth(_viewA.frame)-2*gWidthOffset, 0.4*CGRectGetHeight(_viewA.frame))];
  _viewC.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.4];
  [_viewA addSubview:_viewC];
  
  UILabel *viewName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, gLabelWidth, gLabelHeight)];
  viewName.text = @"View C";
  [_viewC addSubview:viewName];
}

- (void)addViewD {
  _viewD = [[DView alloc] initWithFrame:CGRectMake(gWidthOffset, gHeightOffset, CGRectGetWidth(_viewC.frame)-2*gWidthOffset, 0.4*CGRectGetHeight(_viewC.frame))];
  _viewD.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.6];
  [_viewC addSubview:_viewD];
  
  UILabel *viewName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, gLabelWidth, gLabelHeight)];
  viewName.text = @"View D";
  [_viewD addSubview:viewName];
}

- (void)addViewE {
  _viewE = [[EView alloc] initWithFrame:CGRectMake(gWidthOffset, gHeightOffset + CGRectGetMaxY(_viewD.frame), CGRectGetWidth(_viewC.frame)-2*gWidthOffset, 0.4*CGRectGetHeight(_viewC.frame))];
  _viewE.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.6];
  [_viewC addSubview:_viewE];
  
  UILabel *viewName = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, gLabelWidth, gLabelHeight)];
  viewName.text = @"View E";
  [_viewE addSubview:viewName];
}

- (void) tapViewA:(UITapGestureRecognizer *)recognizer {
  [[[UIAlertView alloc] initWithTitle:nil
                              message:@"ViewA Tapped!"
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
}

- (void) tapViewB:(UITapGestureRecognizer *)recognizer {
  [[[UIAlertView alloc] initWithTitle:nil
                             message:@"ViewB Tapped!"
                            delegate:nil
                   cancelButtonTitle:@"OK"
                   otherButtonTitles:nil] show];
}

- (void) tapViewCenter:(UITapGestureRecognizer *)recognizer {
  [[[UIAlertView alloc] initWithTitle:nil
                              message:@"Center View Tapped!"
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
}

- (void)addViewOverlay {
  _viewOverlay = [[OverlayView alloc] initWithFrame:self.view.bounds];
  _viewOverlay.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.8];
  [self.view addSubview:_viewOverlay];
  
  UIView *centerView = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(_viewOverlay.frame)-100)*0.5, (CGRectGetHeight(_viewOverlay.frame)-100)*0.5, 100, 100)];
  centerView.backgroundColor = [UIColor redColor];
  [_viewOverlay addSubview:centerView];
  
  [centerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapViewCenter:)]];
}
@end
