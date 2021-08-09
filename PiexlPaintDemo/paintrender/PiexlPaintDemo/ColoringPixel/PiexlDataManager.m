//
//  PiexlDataManager.m
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "PiexlDataManager.h"

#import "UIColor+Tool.h"
#import "IntMatrix.h"
#import "CGPointMath.h"
#import "Creator/SlantLineCreator.h"
#import "ToolMethod.h"
#import "LineCreator.h"
#import "HitMatrix.h"
#import "DrawModel.h"

//static const NSInteger kRGBABytesPerPixel = 4;
//static const NSInteger kRGBABitsPerComponent = 8;

@interface PiexlDataManager ()

@property (nonatomic, strong) PixelMatrix *piexlAllMatrix;
@property (nonatomic, strong) SlantLineCreator *slantCreator;
@property (nonatomic, strong) LineCreator *lineCreator;
@property (nonatomic, strong) NSMutableArray<DrawModel *> *drawArray;

@end


@implementation PiexlDataManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static PiexlDataManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}


- (UIImage *)smoothImageFromPiexl:(PixelMatrix *)matrix editColor:(UIColor *)color {
    // 获取所有相连的像素点
    self.piexlAllMatrix = matrix;
    // 颜色分离, key 为颜色hexString
    
    if (![color compareColor:[UIColor clearColor]]) {
        BOOL isFindTag = false;
        for (int i = 0; i < self.drawArray.count; i++) {
            DrawModel *dModel = self.drawArray[i];
            if ([dModel.color compareColor:color]) {
                isFindTag = true;
                PixelMatrix *colorMatrix = [matrix filterMatrixByColor:color];
                if (colorMatrix != nil) {
                    dModel.matrix = colorMatrix;
                    NSArray<SlantSquareModel *> *slantArray = [self.slantCreator findSlantSquareArrayWithMatrix: colorMatrix];
                    dModel.slantArray = slantArray;
                    
                    NSArray<LineResultModel *> *lineArray = [self.lineCreator findLineResultArrayWithMatrix:colorMatrix];
                    dModel.lineArray = lineArray;
                }
            }
        }
        
        if (!isFindTag) {
            PixelMatrix *colorMatrix = [matrix filterMatrixByColor:color];
            if (colorMatrix != nil) {
                DrawModel *dModel = [[DrawModel alloc] init];
                dModel.matrix = colorMatrix;
                dModel.color = color;

                NSArray<SlantSquareModel *> *slantArray = [self.slantCreator findSlantSquareArrayWithMatrix: colorMatrix];
                dModel.slantArray = slantArray;
                
                NSArray<LineResultModel *> *lineArray = [self.lineCreator findLineResultArrayWithMatrix:colorMatrix];
                dModel.lineArray = lineArray;
                [self.drawArray addObject:dModel];
            }
        }
        CGFloat scale = 20.0f;
        __weak __typeof(self)weakSelf = self;
        UIImage *result = [self qmui_imageWithSize:CGSizeMake(self.piexlAllMatrix.col * scale, self.piexlAllMatrix.row * scale) opaque:NO scale:1.0 actions:^(CGContextRef contextRef) {
            for (DrawModel *dModel in weakSelf.drawArray) {
                PixelMatrix *solidMatrix = dModel.matrix;
                UIColor *fillColor = dModel.color;
                HitMatrix *hitMatrix = [[HitMatrix alloc] initWithPixelMatrix:solidMatrix];
                NSArray<LineResultModel *> *lineArray = dModel.lineArray;
                [weakSelf.lineCreator drawLineWithPointValues:lineArray
                                              canvasScale:scale
                                                fillColor:fillColor
                                               contextRef:contextRef];
                
                NSArray<SlantSquareModel *> *slantArray = dModel.slantArray;
                [weakSelf.slantCreator drawSlantSquare:slantArray matrix:solidMatrix contextRef:contextRef scale:scale fillColor:fillColor];
                
                // 画没命中模版的线条
                [hitMatrix updateHitTypeWithSlantSquare:slantArray];
                NSArray<DotSquareModel *> *unHitDotArray = [hitMatrix unHitDotArray];
                [weakSelf.slantCreator drawSlantSquare:unHitDotArray matrix:solidMatrix contextRef:contextRef scale:scale fillColor:fillColor];
            }
        }];
        return result;
    } else {
        return nil;
    }
}

#pragma mark - Lazy load
- (SlantLineCreator *)slantCreator {
    if (_slantCreator == nil) {
        _slantCreator = [[SlantLineCreator alloc] init];
    }
    return _slantCreator;
}

- (LineCreator *)lineCreator {
    if (_lineCreator == nil) {
        _lineCreator = [[LineCreator alloc] init];
    }
    return _lineCreator;
}

#pragma mark - Private Methods

/// 像素数据在bitmap data中的索引
- (NSUInteger)pixelIndexWithRow:(NSUInteger)r
                            col:(NSUInteger)c
                    bytesPerRow:(NSInteger)bytesPerRow
                  bytesPerPixel:(NSInteger)bytesPerPixel {
    return (r * bytesPerRow + c * bytesPerPixel);
}

- (UIImage *)qmui_imageWithSize:(CGSize)size opaque:(BOOL)opaque scale:(CGFloat)scale actions:(void (^)(CGContextRef contextRef))actionBlock {
    if (!actionBlock || size.width <= 0.0 || size.height <= 0.0) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return nil;
    }
    actionBlock(context);
    UIImage *imageOut = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageOut;
}

#pragma mark - Getter && Setter

- (PixelMatrix *)piexlAllMatrix {
    if (_piexlAllMatrix == nil) {
        _piexlAllMatrix = [[PixelMatrix alloc] initWithRow:20 col:20];
    }
    return _piexlAllMatrix;
}

- (NSMutableArray<DrawModel *> *)drawArray {
    if (_drawArray == nil) {
        _drawArray = [NSMutableArray array];
    }
    return _drawArray;
}


/**
 1. 单一格子会变成圆点。（上图红色）

 * 同样，细线条的端头为圆形。

 2. 1×1 格的阶梯会转换为 45° 斜线。（上图绿色）

 * 同理，直线上的 1 格落差会变为斜坡。

 * 斜向相邻的两个像素会发生粘连。

 * 两条相邻的 45° 斜线会彼此分开，仅保持微弱粘连，但三条以上相邻时，中间的部分就会保持棋盘格。

 * 在 3×3 的范围内只要构成局部棋盘格，就不会发生斜线转换。（上图 8 字形图案的中心点）

 3. 2×1 格的阶梯会转换为 26.5° 斜线。（上图蓝色）

 * 同前，两条相邻的 26.5° 斜线会彼此分开（微弱粘连）；但三条以上相邻时，中间的部分就会保持棋盘格。

 4. 3×1 格以上的阶梯不会转换为斜直线，而是在搭接处发生 26.5° 粘连（局部 2×1 阶梯）。（上图棕色）

 5. 1 格的缺口会转换为圆角，而非 45° 倒角。（下图）

 * 更大半径的圆角遵循【规则 2、3】的结合，表现为折线，最终效果也呈圆角。

 * 再大半径的圆弧无法画得光滑，即使使用自带的「圆形工具」绘制，得到的结果也是以上【规则 2、3、4】 的组合而成的多边形
 */

@end
