//
//  ParalleSquareModel.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/28.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SlantSquareModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ParalleSquareModel: SlantSquareModel

+ (PixelMatrix *)compareMitrix;
+ (NSArray<ParalleSquareModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j;

@end

NS_ASSUME_NONNULL_END
