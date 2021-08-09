//
//  WheelSquareLeftModel.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/29.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SlantSquareModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface WheelSquareLeftModel: SlantSquareModel

+ (PixelMatrix *)compareMitrix;
+ (NSArray<WheelSquareLeftModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j;

@end

NS_ASSUME_NONNULL_END
