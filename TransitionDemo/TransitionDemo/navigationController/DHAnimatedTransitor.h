//
//  DHAnimatedTransitor.h
//  TransitionDemo
//
//  Created by User on 2019/7/11.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^TransitionBlock)(id<UIViewControllerContextTransitioning> transitionContext);

@interface DHAnimatedTransitor : NSObject <UIViewControllerAnimatedTransitioning>

// 设置过渡时长, default 0.5s
@property (nonatomic, assign) NSTimeInterval transitionDuration;

@property (nonatomic, assign) UINavigationControllerOperation operation;

@end

NS_ASSUME_NONNULL_END
