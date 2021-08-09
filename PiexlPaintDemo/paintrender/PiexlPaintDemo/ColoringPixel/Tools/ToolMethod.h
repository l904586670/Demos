//
//  ToolMethod.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/25.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixelModel.h"
#import "PixelMatrix.h"

NS_ASSUME_NONNULL_BEGIN

@interface ToolMethod : NSObject

/// 从像素矩阵中获取指定点的数据模型
/// @param matrix 像素矩阵
/// @param row 行
/// @param col 列
+ (PixelModel *)piexlModelWithMatrix:(PixelMatrix *) matrix
                                 row:(NSUInteger) row
                              column:(NSUInteger) col;

/// 判断两个点的颜色是否相同
/// @param matrix 像素数组 
/// @param pointOne 点1
/// @param otherPoint 点2
+ (BOOL)colorIsEqualWithMatrix:(PixelMatrix *) matrix
                      pointOne:(CGPoint)pointOne
                    otherPoint:(CGPoint)otherPoint;

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end

NS_ASSUME_NONNULL_END
