//
//  RandomTool.h
//  SystomMapKitDemo
//
//  Created by User on 2019/7/23.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RandomTool : NSObject

/**
 * 随机生成指定范围[0, max)内的整数值
 */
+ (NSInteger)randomInteger:(NSInteger)max;

/**
 * 随机生成指定范围[min, max)内的整数值
 */
+ (NSInteger)randomIntegerWithMin:(NSInteger)min max:(NSInteger)max;

/**
 * 随机生成指定范围[0.0, 1.0]内的浮点值
 */
+ (float)randomFloat;

/**
 * 随机生成指定范围[0.0, max]内的浮点值
 */
+ (float)randomFloat:(float)max;

/**
 * 随机生成指定范围[min, max]内的浮点值
 */
+ (float)randomFloatWithMin:(float)min max:(float)max;

/**
 *  按照ratio的概率随机
 *
 *  @param ratio [0, 1]区间的浮点数
 *
 *  @return YES表示随机命中
 */
+ (BOOL)randomRatio:(float)ratio;


@end

NS_ASSUME_NONNULL_END
