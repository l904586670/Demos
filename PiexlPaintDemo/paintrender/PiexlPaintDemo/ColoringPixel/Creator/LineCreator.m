//
//  LineCreator.m
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/25.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "LineCreator.h"

#import "ToolMethod.h"
#import "PixelModel.h"
#import "IntMatrix.h"

@implementation LineCreator


/**
 *长度大于等于3的连续点
 * 从左上至右下遍历所有点
 * 对每一个点进行向有、向下持续查点
 */
- (NSArray<LineResultModel *> *)findLineResultArrayWithMatrix:(PixelMatrix *)pixelMatrix {
    if (!pixelMatrix) {
        return nil;
    }
    
    NSMutableSet<LineResultModel *> *resultArray = [NSMutableSet set];
    
    IntMatrix *horizontalIntMatrix = [[IntMatrix alloc] initWithRow:pixelMatrix.row col:pixelMatrix.col value:0];
    IntMatrix *verticalIntMatrix = [[IntMatrix alloc] initWithRow:pixelMatrix.row col:pixelMatrix.col value:0];
    NSInteger minCount = 3;
    
    for (NSInteger row = 0; row < pixelMatrix.row; row ++) {
        for (NSInteger col = 0; col < pixelMatrix.col; col ++) {
            PixelModel *pixelModel = [ToolMethod piexlModelWithMatrix:pixelMatrix row:row column:col];
            if (!pixelModel || pixelModel.alpha == 0) {
                continue;
            }
            
            NSLog(@"current point color alpha : %ld row : %@, col : %@",  pixelModel.alpha, @(row), @(col));
            
            NSInteger intValue = [horizontalIntMatrix intValueAtRow:row col:col];
            if (intValue != 1) {
                // 查询
                    NSInteger horizontalOffset = 1;
                    CGPoint currentPoint = CGPointMake(col, row);
                    CGPoint nextPoint = CGPointMake(col + 1, row);
                    BOOL colorEqual = [ToolMethod colorIsEqualWithMatrix:pixelMatrix
                                                                pointOne:currentPoint
                                                              otherPoint:nextPoint];
                    while (colorEqual) {
                        horizontalOffset += 1;
                        nextPoint = CGPointMake(col + horizontalOffset, row);
                        colorEqual = [ToolMethod colorIsEqualWithMatrix:pixelMatrix
                                                               pointOne:currentPoint
                                                             otherPoint:nextPoint];
                    }
                
                    if (horizontalOffset >= minCount) {
                        for (NSInteger i = col; i < (col + horizontalOffset - 1); i++) {
                            [horizontalIntMatrix setIntValue:1 row:row col:i];
                        }
                        
                        LineResultModel *resultModel = [[LineResultModel alloc] init];
                        resultModel.startPoint = currentPoint;
                        resultModel.endPoint = CGPointMake(nextPoint.x - 1, nextPoint.y);
                        [resultArray addObject:resultModel];
                        
                        NSLog(@"[a]horizontal start : %@ end : %@", NSStringFromCGPoint(currentPoint), NSStringFromCGPoint(nextPoint));
                    }
            }
            
            NSInteger horizontalValue = [verticalIntMatrix intValueAtRow:row col:col];
            if (horizontalValue != 1) {
                // 查询
                NSInteger verticalOffset = 1;
                CGPoint currentPoint = CGPointMake(col, row);
                CGPoint nextPoint = CGPointMake(col, row + verticalOffset);
                BOOL colorEqual = [ToolMethod colorIsEqualWithMatrix:pixelMatrix
                                                            pointOne:currentPoint
                                                          otherPoint:nextPoint];
                
                while (colorEqual) {
                    verticalOffset += 1;
                    nextPoint = CGPointMake(col, row + verticalOffset);
                    
                    colorEqual = [ToolMethod colorIsEqualWithMatrix:pixelMatrix
                                                           pointOne:currentPoint
                                                         otherPoint:nextPoint];
                }
                
                if (verticalOffset >= minCount) {
                    for (NSInteger i = row; i < (verticalOffset + row - 1); i++) {
                        [verticalIntMatrix setIntValue:1 row:i col:col];
                    }
                    
                    NSLog(@"[a]vertical start : %@ end : %@", NSStringFromCGPoint(currentPoint), NSStringFromCGPoint(nextPoint));
                    LineResultModel *resultModel = [[LineResultModel alloc] init];
                    resultModel.startPoint = currentPoint;
                    resultModel.endPoint = CGPointMake(nextPoint.x, nextPoint.y - 1);;
                    [resultArray addObject:resultModel];
                }
            }
        }
    }
    
//    [horizontalIntMatrix printLogInfo];
//    UIImage *resultImage = [horizontalIntMatrix logImage];
//    [verticalIntMatrix printLogInfo];
//    UIImage *resultImage1 = [verticalIntMatrix logImage];

    return [resultArray copy];
}
- (void)drawLineWithPointValues:(NSArray <LineResultModel *>*)lineResults
                    canvasScale:(CGFloat)scale
                      fillColor:(UIColor *)fillColor
                     contextRef:(CGContextRef)contextRef {
    if (!lineResults || !contextRef || !fillColor) {
        return;
    }
    
    CGFloat offset = 0.5;
    
    [lineResults enumerateObjectsUsingBlock:^(LineResultModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGContextSetStrokeColorWithColor(contextRef, fillColor.CGColor);
        CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
        CGContextSetLineWidth(contextRef, scale*1.3);
        CGContextSetLineJoin(contextRef, kCGLineJoinRound);
        CGContextSetLineCap(contextRef, kCGLineCapRound);
        CGContextMoveToPoint(contextRef, (obj.startPoint.x + offset) * scale, (obj.startPoint.y + offset) * scale);  //起点坐标
        CGContextAddLineToPoint(contextRef, (obj.endPoint.x + offset) * scale, (obj.endPoint.y + offset) * scale);
        CGContextStrokePath(contextRef);
    }];
}

@end
