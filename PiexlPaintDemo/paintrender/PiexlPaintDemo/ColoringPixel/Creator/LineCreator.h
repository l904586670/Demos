//
//  LineCreator.h
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/25.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LineResultModel.h"
#import "PixelMatrix.h"

NS_ASSUME_NONNULL_BEGIN

@interface LineCreator : NSObject

- (NSArray<LineResultModel *> *)findLineResultArrayWithMatrix:(PixelMatrix *)pixelMatrix;

- (void)drawLineWithPointValues:(NSArray <LineResultModel *>*)lineResults
                    canvasScale:(CGFloat)scale
                      fillColor:(UIColor *)fillColor
                     contextRef:(CGContextRef)contextRef;

@end

NS_ASSUME_NONNULL_END
