//
//  UIViewController+Utils.h
//  LearnMatelDemo
//
//  Created by User on 2019/7/27.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Utils)

@property (nonatomic, assign, readonly) UIEdgeInsets safeAreaEdgeInsets;

@property (nonatomic, assign, readonly) CGRect contentRect;

@property (nonatomic, assign, readonly) CGSize screenSize;

@end

NS_ASSUME_NONNULL_END
