//
//  ObliqueLeftSquareModel.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/6/4.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SlantSquareModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ObliqueLeftSquareModel : SlantSquareModel

+ (PixelMatrix *)compareMitrix;
+ (NSArray<ObliqueLeftSquareModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j;

@end

NS_ASSUME_NONNULL_END
