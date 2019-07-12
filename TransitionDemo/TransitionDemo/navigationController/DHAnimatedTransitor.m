//
//  DHAnimatedTransitor.m
//  TransitionDemo
//
//  Created by User on 2019/7/11.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "DHAnimatedTransitor.h"

@implementation DHAnimatedTransitor

- (instancetype)init {
  self = [super init];
  if (self) {
    _transitionDuration = 0.5;
    _operation = UINavigationControllerOperationNone;
  }
  return self;
}


#pragma mark - UIViewControllerAnimatedTransitioning

// 返回动画时长
- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext {
  return _transitionDuration;
}


- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
  
  [self animateTransitionWithNoInteractive:transitionContext operation:_operation];
  
  //取出转场前后的视图控制器
 
  //如果加入了手势交互转场，就需要根据手势交互动作是否完成/取消来做操作，完成标记YES，取消标记NO，必须标记，否则系统认为还处于动画过程中，会出现无法交互之类的bug
//  [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
//  if ([transitionContext transitionWasCancelled]) {
//    //如果取消转场
//  } else {
//    //完成转场
//  }
  
  
}


- (void)animateTransitionWithNoInteractive:(id <UIViewControllerContextTransitioning>)transitionContext operation:(UINavigationControllerOperation)operation {
  if (operation == UINavigationControllerOperationNone) {
    NSAssert(NO, @"operation need set value");
    return;
  }
  
  UIViewController *fromVC = (UIViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
  UIViewController *toVC = (UIViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
  
  // 取出转场前后视图控制器上的视图view
  UIView * toView = [transitionContext viewForKey:UITransitionContextToViewKey];
  UIView * fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
  if (!toView) {
    toView = toVC.view;
  }
  if (!fromView) {
    fromView = fromVC.view;
  }
  
  // 把要做动画的view 添加到 临时 containerView 上
  UIView *containerView = [transitionContext containerView];
  // push 时, toView 要在 fromView 上面; pop时,相反
  if (operation == UINavigationControllerOperationPush) {
    [containerView addSubview:fromView];
    [containerView addSubview:toView];
  } else if (operation == UINavigationControllerOperationPop) {
    [containerView addSubview:toView];
    [containerView addSubview:fromView];
  }
  
  // 做一个类似Present 从下到上的Push/Pop动画
  CGRect screenBounds = [UIScreen mainScreen].bounds;
  
  CGRect targetRect = screenBounds;
  if (operation == UINavigationControllerOperationPush) {
    toView.frame = CGRectOffset(screenBounds, 0, CGRectGetHeight(screenBounds));
  } else if (operation == UINavigationControllerOperationPop) {
    targetRect = CGRectOffset(screenBounds, 0, CGRectGetHeight(screenBounds));
  }
  
  
  [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
    if (operation == UINavigationControllerOperationPush) {
      toView.frame = targetRect;
    } else if (operation == UINavigationControllerOperationPop) {
      fromView.frame = targetRect;
    }
  } completion:^(BOOL finished) {
    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
  }];
}


///// A conforming object implements this method if the transition it creates can
///// be interrupted. For example, it could return an instance of a
///// UIViewPropertyAnimator. It is expected that this method will return the same
///// instance for the life of a transition.
//- (id <UIViewImplicitlyAnimating>) interruptibleAnimatorForTransition:(id <UIViewControllerContextTransitioning>)transitionContext NS_AVAILABLE_IOS(10_0);
//
//// This is a convenience and if implemented will be invoked by the system when the transition context's completeTransition: method is invoked.
- (void)animationEnded:(BOOL) transitionCompleted {
  NSLog(@"animationEnded : %d", transitionCompleted);
}

@end
