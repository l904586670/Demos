//
//  PiexlDataManager.h
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import "PixelMatrix.h"
#import "PixelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PiexlDataManager : NSObject

+ (instancetype)sharedInstance;

- (UIImage *)smoothImageFromPiexl:(PixelMatrix *)matrix editColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
