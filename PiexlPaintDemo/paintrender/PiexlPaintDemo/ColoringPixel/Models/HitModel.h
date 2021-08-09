//
//  HitModel.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/29.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SlantSquareModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HitModel : NSObject

@property (nonatomic, assign) BOOL isDraw;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *hitTypeArray;

@end

NS_ASSUME_NONNULL_END
