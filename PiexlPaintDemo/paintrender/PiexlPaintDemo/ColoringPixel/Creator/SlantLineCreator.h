//
//  SlantLineCreator.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/25.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModelHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface SlantLineCreator : NSObject

- (NSArray<SlantSquareModel *> *)findSlantSquareArrayWithMatrix:(PixelMatrix *)pixelMatrix;

- (void)drawSlantSquare:(NSArray<SlantSquareModel *> *)slantArray
                 matrix:(PixelMatrix *)pixelMatrix
             contextRef:(CGContextRef)contextRef
                  scale:(CGFloat)scale
              fillColor:(UIColor *)fillColor;

@end

NS_ASSUME_NONNULL_END
