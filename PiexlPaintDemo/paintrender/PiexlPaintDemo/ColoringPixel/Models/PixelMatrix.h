//
//  PixelMatrix.h
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixelModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelMatrix : NSObject


/// 行 对应CGPoint.y
@property(nonatomic, assign, readonly) NSInteger row;

/// 列 对应CGPoint.x
@property(nonatomic, assign, readonly) NSInteger col;

- (instancetype)initWithRow:(NSInteger)row col:(NSInteger)col;

- (void)setValue:(PixelModel *)value row:(NSInteger)r col:(NSInteger)c;
- (void)setValue:(PixelModel *)value at:(CGPoint)position;

// 设置矩阵比较元素忽略标记
- (void)setCompareIgnore:(BOOL )isIgnore row:(NSInteger)r col:(NSInteger)c;

- (PixelModel *)valueAtRow:(NSInteger)r col:(NSInteger)c;
- (PixelModel *)valueAt:(CGPoint)position;

- (BOOL)invalid:(CGPoint)position;

- (PixelMatrix *)subMatrixWithRow:(NSInteger)row col:(NSInteger)col offsetRow:(NSInteger)offsetRow offsetCol:(NSInteger)offsetCol;

- (Boolean)compareWithMatrix:(PixelMatrix *)matrix;

- (PixelMatrix *)filterMatrixByColor:(UIColor *)color;


#pragma mark - Debug Methods

- (UIImage *)pixelPreviewImage;
- (void)printLogInfo;

@end

NS_ASSUME_NONNULL_END
