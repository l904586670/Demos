//
//  DrawModel.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/6/8.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SlantSquareModel.h"
#import "LineResultModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DrawModel : NSObject

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) PixelMatrix *matrix;
@property (nonatomic, strong) NSArray<SlantSquareModel *> *slantArray;
@property (nonatomic, strong) NSArray<LineResultModel *> *lineArray;

@end

NS_ASSUME_NONNULL_END
