//
//  NavigationNotice.h
//  TransitionDemo
//
//  Created by User on 2019/7/12.
//  Copyright © 2019 Rock. All rights reserved.
//

#ifndef NavigationNotice_h
#define NavigationNotice_h

/**
 首先要先清除 fromVC , toVC
 fromVC 当前的控制器, toVC 将要显示的控制器
 
 
 协议
 UIViewControllerAnimatedTransitioning
 // 返回过渡时长
 - (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext;
 
 // This method can only  be a nop if the transition is interactive and not a percentDriven interactive transition.
 // 在此方法中实现具体的过渡动画, 从transitionContext 取出 FromVC fromView ToVC toView 添加到containerView 上实现具体的动画, 在动画完成后调用 completeTransition. 在有手势控制时控制百分比和完成取消状态
 - (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext;
 
 @optional
 
 /// A conforming object implements this method if the transition it creates can
 /// be interrupted. For example, it could return an instance of a
 /// UIViewPropertyAnimator. It is expected that this method will return the same
 /// instance for the life of a transition.
 - (id <UIViewImplicitlyAnimating>) interruptibleAnimatorForTransition:(id <UIViewControllerContextTransitioning>)transitionContext NS_AVAILABLE_IOS(10_0);
 
 // This is a convenience and if implemented will be invoked by the system when the transition context's completeTransition: method is invoked.
 - (void)animationEnded:(BOOL) transitionCompleted;
 
 
 
 导航控制器注意事项:
 1. 设置代理 self.navigationController.delegate = self;
 2. 实现 UINavigationControllerDelegate 协议方法
    主要实现
 
 // 返回一个 遵守 UIViewControllerAnimatedTransitioning 协议的对象
 - (nullable id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
 animationControllerForOperation:(UINavigationControllerOperation)operation
 fromViewController:(UIViewController *)fromVC
 toViewController:(UIViewController *)toVC {}
 
 - (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController{}
 两个方法 会先调用 上面的方法获取operation类型 Push or Pop, 然后在调用下面的方法查看是否需要手势
 

 */


#endif /* NavigationNotice_h */
