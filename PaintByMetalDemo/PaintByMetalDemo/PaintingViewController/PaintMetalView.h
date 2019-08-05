//
//  PaintMetalView.h
//  PaintByMetalDemo
//
//  Created by User on 2019/8/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface PaintMetalView : UIView

// 笔刷大小, default 30
@property (nonatomic, assign) float brushSize;
// 涂抹颜色, 默认红色
@property (nonatomic, strong) UIColor *brushColor;

@end

NS_ASSUME_NONNULL_END
