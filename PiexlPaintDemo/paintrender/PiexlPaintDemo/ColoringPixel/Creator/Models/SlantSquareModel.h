//
//  SlantSquareModel.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/25.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PixelMatrix.h"
#import "PixelMatrix+Transfer.h"
#import "SlantSquareModel.h"
#import "ToolMethod.h"

// 向下斜线， 向上斜线, 圆角(左上角)
typedef NS_ENUM(NSInteger, SquareType) {
    SquareTypeUndefined,
    SquareTypeSlantLine,
    SquareTypeFillet,
    SquareTypeTriangle,
    SquareTypeParalle,
    SquareTypeDotSquare,
    SquareTypeDotResult,
    SquareTypeWheelSquare,
    SquareTypeRightAngSquare,
    SquareTypeM,
    SquareTypeObliqueLeft,
    SquareTypeObliqueRight,
    SquareTypeDotBig,
    SquareTypeDotX
};

// 模版方向
typedef NS_ENUM(NSInteger, SquareDirect) {
    SquareDirectUndefined,
    SquareDirectUp,
    SquareDirect90,
    SquareDirect180,
    SquareDirect270
};


NS_ASSUME_NONNULL_BEGIN

@interface SlantSquareModel : NSObject
@property (nonatomic, assign) SquareType type;
@property (nonatomic, assign) SquareDirect direct;
@property (nonatomic, assign) CGFloat positionX;
@property (nonatomic, assign) CGFloat positionY;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@end

NS_ASSUME_NONNULL_END
