//
//  NavSecondViewController.m
//  TransitionDemo
//
//  Created by User on 2019/7/11.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "NavSecondViewController.h"

#import "NavThirdViewController.h"
#import "DHAnimatedTransitor.h"

@interface NavSecondViewController ()

@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactiveTransition;

@end

@implementation NavSecondViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.title = @"navSecondVC";
  self.view.backgroundColor = [UIColor lightGrayColor];
    // Do any additional setup after loading the view.
  
  [self btnWithAction:@selector(onNext)];
  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  self.navigationController.delegate = self;
}

- (UIButton *)btnWithAction:(SEL)action {
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
  btn.frame = CGRectMake(0, 0, 200, 50);
  [btn setTitle:@"跳转到下个控制器" forState:UIControlStateNormal];
  btn.backgroundColor = [UIColor blueColor];
  [self.view addSubview:btn];
  btn.center = self.view.center;
  
  [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  
  return btn;
}

- (void)onNext {
  
  self.navigationController.delegate = self;
  
  NavThirdViewController *nextVC = [[NavThirdViewController alloc] init];
  [self.navigationController pushViewController:nextVC animated:YES];
}

#pragma mark - UINavigationControllerDelegate

// Called when the navigation controller shows a new top view controller via a push, pop or setting of the view controller stack.
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  NSLog(@"willShowViewController");
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  NSLog(@"didShowViewController");
}

// tvOS 禁用
//- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController {
//
//}
//
//// tvOS 禁用
//- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController {
//
//}



// 无手势
- (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                            animationControllerForOperation:(UINavigationControllerOperation)operation
                                                         fromViewController:(UIViewController *)fromVC
                                                           toViewController:(UIViewController *)toVC {
  // navigationController 当前的导航控制器
  //  operation           Push Or Pop
  // fromVC      从哪个控制器Push or Pop
  // toVC        到哪个控制器
  NSLog(@"fromVC : %@, toVC : %@", fromVC, toVC);
  DHAnimatedTransitor *transitor = [[DHAnimatedTransitor alloc] init];
  transitor.operation = operation;
  return transitor;
}

// 手势过渡
- (nullable id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                                   interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController  {
  UIPercentDrivenInteractiveTransition *interactiveTransition = [[UIPercentDrivenInteractiveTransition alloc] init];
  self.interactiveTransition = interactiveTransition;
  return interactiveTransition;
}


@end
