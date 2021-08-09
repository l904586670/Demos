//
//  IntMatrix.h
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//
// 数字矩阵，0/1 用来判断数据是否统计过

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IntMatrix : NSObject

/// 行 对应CGPoint.y
@property(nonatomic, assign, readonly) NSInteger row;

/// 列 对应CGPoint.x
@property(nonatomic, assign, readonly) NSInteger col;

- (instancetype)initWithRow:(NSInteger)row col:(NSInteger)col;
- (instancetype)initWithRow:(NSInteger)row col:(NSInteger)col value:(NSInteger)initValue;

- (void)setIntValue:(NSInteger)value row:(NSInteger)r col:(NSInteger)c;
- (void)setIntValue:(NSInteger)value at:(CGPoint)position;

- (NSInteger)intValueAtRow:(NSInteger)r col:(NSInteger)c;
- (NSInteger)intValueAt:(CGPoint)position;

- (BOOL)invalid:(CGPoint)position;

- (UIImage *)logImage;
- (void)printLogInfo;

@end

NS_ASSUME_NONNULL_END
