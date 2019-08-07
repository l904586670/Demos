//
//  BaseMetalShaderFilter.h
//  MetalSystomFilterDemo
//
//  Created by User on 2019/8/6.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseMetalShaderFilter : NSObject


/**
 饱和度 [0.0, 2.0], default : 1.0
 */
@property (nonatomic, assign) float saturation;

/**
 对比度 [0.5, 1.5], default : 1.0
 */
@property (nonatomic, assign) float contrast;

/**
 亮度 [0.5, 1.5], default : 1.0
 */
@property (nonatomic, assign) float brightness;

/**
 色温 [-1.0,1.0], default : 0.0
 */
@property (nonatomic, assign) float temperature;

/**
 透明度 [0.0, 1.0], default : 1.0
 */
@property (nonatomic, assign) float alpha;

+ (instancetype)shareInstance;

- (UIImage *)filterWithOriginImage:(UIImage *)image;

- (UIImage *)lutFilterWithOriginImage:(UIImage *)image
                             lutImage:(UIImage *)lutImage;

@end

NS_ASSUME_NONNULL_END
