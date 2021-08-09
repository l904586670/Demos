//
//  NSObject+PixelMatrix_Transfer.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/28.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixelMatrix.h"

NS_ASSUME_NONNULL_BEGIN

@interface PixelMatrix (Transfer)

// 向左旋转
- (PixelMatrix *)transferLeft;

@end

NS_ASSUME_NONNULL_END
