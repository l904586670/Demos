//
//  HitMatrix.h
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ModelHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface HitMatrix : NSObject

/// 行 对应CGPoint.y
@property(nonatomic, assign, readonly) NSInteger row;

/// 列 对应CGPoint.x
@property(nonatomic, assign, readonly) NSInteger col;

- (instancetype)initWithPixelMatrix:(PixelMatrix *)matrix;

- (void)addValue:(SquareType)value row:(NSInteger)r col:(NSInteger)c;

- (HitModel*)valueAtRow:(NSInteger)r col:(NSInteger)c;

- (NSArray<DotSquareModel *> *)unHitDotArray;

- (void)updateHitTypeWithSlantSquare:(NSArray<SlantSquareModel *> *)slantArray;

@end

NS_ASSUME_NONNULL_END
