//
//  SlantLineCreator.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/25.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "SlantLineCreator.h"
#import "ToolMethod.h"

/**
 * 2. 1×1 格的阶梯会转换为 45° 斜线。（上图绿色）

 * 同理，直线上的 1 格落差会变为斜坡。

 * 斜向相邻的两个像素会发生粘连。

 * 两条相邻的 45° 斜线会彼此分开，仅保持微弱粘连，但三条以上相邻时，中间的部分就会保持棋盘格。

 * 在 3×3 的范围内只要构成局部棋盘格，就不会发生斜线转换。（上图 8 字形图案的中心点）

 * 3. 2×1 格的阶梯会转换为 26.5° 斜线。（上图蓝色）

 * 同前，两条相邻的 26.5° 斜线会彼此分开（微弱粘连）；但三条以上相邻时，中间的部分就会保持棋盘格。

 * 4. 3×1 格以上的阶梯不会转换为斜直线，而是在搭接处发生 26.5° 粘连（局部 2×1 阶梯）。（上图棕色）
 */

// 模版画矩形

@implementation SlantLineCreator

- (NSArray<SlantSquareModel *> *)findSlantSquareArrayWithMatrix:(PixelMatrix *)pixelMatrix {
    NSMutableArray *resultArray = [NSMutableArray array];
    if (pixelMatrix != nil) {
        for (int i = 0; i < pixelMatrix.row; i++) {
            for (int j = 0; j < pixelMatrix.col; j++) {
                Boolean isTriangleTag = false;
                Boolean isFilletTag = false;
                Boolean isParalleTag = false;
                Boolean isLineTag = false;
                
                PixelModel *pixelModel = [ToolMethod piexlModelWithMatrix:pixelMatrix row:i column:j];
                if (pixelModel) {
                    NSArray<ParalleSquareModel *> *modelArray = [ParalleSquareModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (modelArray.count > 0) {
                        [resultArray addObjectsFromArray:modelArray];
                        isParalleTag = true;
                    }
                    
                    NSArray<FilletSquareModel *> *filletArray = [FilletSquareModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (filletArray.count > 0) {
                        [resultArray addObjectsFromArray:filletArray];
                        isFilletTag = true;
                    }
                    
                    NSArray<TriangleSquareModel *> *triangleModel = [TriangleSquareModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (triangleModel.count > 0) {
                        [resultArray addObjectsFromArray:triangleModel];
                        isTriangleTag = true;
                    }
                    
                    NSArray<WheelSquareLeftModel *> *wheelArray = [WheelSquareLeftModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (wheelArray.count > 0) {
                        [resultArray addObjectsFromArray:wheelArray];
                    }
                    
                    NSArray<WheelSquareRightModel *> *wheelRightArray = [WheelSquareRightModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (wheelRightArray.count > 0) {
                        [resultArray addObjectsFromArray:wheelRightArray];
                    }
                    
                    NSArray<RightAngSquareModel *> *rightAnglArray = [RightAngSquareModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (rightAnglArray.count > 0) {
                        [resultArray addObjectsFromArray:rightAnglArray];
                    }
                    
                    NSArray<MSquareModel *> *mArray = [MSquareModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (mArray.count > 0) {
                        [resultArray addObjectsFromArray:mArray];
                    }
                    
                    NSArray<ObliqueLeftSquareModel *> *olArray = [ObliqueLeftSquareModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (olArray.count > 0) {
                        [resultArray addObjectsFromArray:olArray];
                    }
                    
                    NSArray<ObliqueRightSquareModel *> *orArray = [ObliqueRightSquareModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (orArray.count > 0) {
                        [resultArray addObjectsFromArray:orArray];
                    }
                    
                    NSArray<DotBitSquareModel *> *dBArray = [DotBitSquareModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                    if (dBArray.count > 0) {
                        [resultArray addObjectsFromArray:dBArray];
                    }
                    
                    if (!isFilletTag && !isParalleTag && !isTriangleTag) {
                        NSArray<LineSquareModel *> *lineArray = [LineSquareModel checkWithMitrix:pixelMatrix model:pixelModel row:i col:j];
                        if (filletArray != nil) {
                            [resultArray addObjectsFromArray:lineArray];
                            isLineTag = true;
                        }
                    }
                }
            }
        }
    }
    return [resultArray copy];
}

- (void)drawSlantSquare:(NSArray<SlantSquareModel *> *)slantArray matrix:(PixelMatrix *)pixelMatrix contextRef:(CGContextRef)contextRef scale:(CGFloat)scale fillColor:(UIColor *)fillColor {
    if (!fillColor) {
        return;
    }

    CGContextSetStrokeColorWithColor(contextRef, fillColor.CGColor);
    CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
    CGContextSetLineWidth(contextRef, scale*1.3);
    CGContextSetLineJoin(contextRef, kCGLineJoinRound);
    CGContextSetLineCap(contextRef, kCGLineCapRound);
    
    if (slantArray.count > 0 && contextRef != nil && pixelMatrix != nil) {
        for (int i = 0; i < slantArray.count; i++) {
            SlantSquareModel *model = slantArray[i];
            
            if (model.type == SquareTypeSlantLine) {
                // 斜线模版
                CGPoint p0;
                CGPoint p1;
                if (model.direct == SquareDirectUp || model.direct == SquareDirect180) {
                    p0 = CGPointMake(model.positionX + 1.5, model.positionY + 2.5);
                    p1 = CGPointMake(model.positionX + 2.5 , model.positionY + 1.5);
                } else if (model.direct == SquareDirect90 || model.direct == SquareDirect270) {
                    p0 = CGPointMake(model.positionX + 1.5, model.positionY + 1.5);
                    p1 = CGPointMake(model.positionX + 2.5 , model.positionY + 2.5);
                }
                CGContextMoveToPoint(contextRef, p0.x * scale, p0.y * scale);
                CGContextAddLineToPoint(contextRef, p1.x * scale, p1.y * scale);
                CGContextStrokePath(contextRef);
            } else if (model.type == SquareTypeFillet) {
                // 圆弧模版
                CGFloat raduis = 1.5 * scale;
                if (model.direct == SquareDirectUp) {
                    CGFloat arcX = (model.positionX + 3)*scale;
                    CGFloat arcY = (model.positionY + 3)*scale;
                    CGContextMoveToPoint(contextRef,(model.positionX + 1.6) * scale, (model.positionY+2.5) * scale);
                    CGContextAddArc(contextRef, arcX, arcY, raduis, M_PI, M_PI * 1.5, 0);
                    CGContextStrokePath(contextRef);
                } else if (model.direct == SquareDirect90) {
                    CGFloat arcX = (model.positionX + 3)*scale;
                    CGFloat arcY = (model.positionY + 2)*scale;
                    CGContextMoveToPoint(contextRef,(model.positionX + 1.6) * scale, (model.positionY+2.5) * scale);
                    CGContextAddArc(contextRef, arcX, arcY, raduis, M_PI, M_PI_2, 1);
                    CGContextStrokePath(contextRef);
                } else if (model.direct == SquareDirect180) {
                    CGFloat arcX = (model.positionX + 2)*scale;
                    CGFloat arcY = (model.positionY + 2)*scale;
                    CGContextMoveToPoint(contextRef,(model.positionX + 3.5) * scale, (model.positionY+2.2) * scale);
                    CGContextAddArc(contextRef, arcX, arcY, raduis, 0, M_PI_2, 0);
                    CGContextStrokePath(contextRef);
                } else if (model.direct == SquareDirect270) {
                    CGFloat arcX = (model.positionX + 2)*scale;
                    CGFloat arcY = (model.positionY + 3)*scale;
                    CGContextMoveToPoint(contextRef,(model.positionX + 2.4) * scale, (model.positionY+1.6) * scale);
                    CGContextAddArc(contextRef, arcX, arcY, raduis, -1 *M_PI_2, 0, 0);
                    CGContextStrokePath(contextRef);
                }
            } else if (model.type == SquareTypeParalle) {
                if (model.direct == SquareDirectUp) {
                    CGContextMoveToPoint(contextRef,(model.positionX + 1.5)*scale, (model.positionY + 2.5)*scale);
                    CGPoint sPoints[4];
                    sPoints[0] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 2.5)*scale);
                    sPoints[1] =CGPointMake((model.positionX + 4.5)*scale, (model.positionY + 2.5)*scale);
                    sPoints[2] =CGPointMake((model.positionX + 4)*scale, (model.positionY + 1.5)*scale);
                    sPoints[3] =CGPointMake((model.positionX + 2)*scale, (model.positionY + 1.5)*scale);
                    CGContextAddLines(contextRef, sPoints, sizeof(sPoints)/sizeof(sPoints[0]));
                    CGContextClosePath(contextRef);
                    CGContextDrawPath(contextRef, kCGPathFillStroke);
                } else if (model.direct == SquareDirect90) {
                    CGContextMoveToPoint(contextRef,(model.positionX + 2.5)*scale, (model.positionY + 1.5)*scale);
                    CGPoint sPoints[4];
                    sPoints[0] =CGPointMake((model.positionX + 2.5)*scale, (model.positionY + 1.5)*scale);
                    sPoints[1] =CGPointMake((model.positionX + 2.5)*scale, (model.positionY + 4.5)*scale);
                    sPoints[2] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 4)*scale);
                    sPoints[3] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 2)*scale);
                    CGContextAddLines(contextRef, sPoints, sizeof(sPoints)/sizeof(sPoints[0]));
                    CGContextClosePath(contextRef);
                    CGContextDrawPath(contextRef, kCGPathFillStroke);
                } else if (model.direct == SquareDirect180) {
                    CGContextMoveToPoint(contextRef,(model.positionX + 1.5)*scale, (model.positionY + 1.5)*scale);
                    CGPoint sPoints[4];
                    sPoints[0] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 1.5)*scale);
                    sPoints[1] =CGPointMake((model.positionX + 4.5)*scale, (model.positionY + 1.5)*scale);
                    sPoints[2] =CGPointMake((model.positionX + 4)*scale, (model.positionY + 2.5)*scale);
                    sPoints[3] =CGPointMake((model.positionX + 2)*scale, (model.positionY + 2.5)*scale);
                    CGContextAddLines(contextRef, sPoints, sizeof(sPoints)/sizeof(sPoints[0]));
                    CGContextClosePath(contextRef);
                    CGContextDrawPath(contextRef, kCGPathFillStroke);
                } else if (model.direct == SquareDirect270) {
                    CGContextMoveToPoint(contextRef,(model.positionX + 1.5)*scale, (model.positionY + 1.5)*scale);
                    CGPoint sPoints[4];
                    sPoints[0] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 1.5)*scale);
                    sPoints[1] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 4.5)*scale);
                    sPoints[2] =CGPointMake((model.positionX + 2.5)*scale, (model.positionY + 4)*scale);
                    sPoints[3] =CGPointMake((model.positionX + 2.5)*scale, (model.positionY + 2)*scale);
                    CGContextAddLines(contextRef, sPoints, sizeof(sPoints)/sizeof(sPoints[0]));
                    CGContextClosePath(contextRef);
                    CGContextDrawPath(contextRef, kCGPathFillStroke);
                }
            } else if (model.type == SquareTypeTriangle) {
                if (model.direct == SquareDirectUp) {
                    CGContextMoveToPoint(contextRef,(model.positionX + 1)*scale, (model.positionY + 3.5)*scale);
                    CGPoint sPoints[3];
                    sPoints[0] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 3.5)*scale);
                    sPoints[1] =CGPointMake((model.positionX + 5.5)*scale, (model.positionY + 3.5)*scale);
                    sPoints[2] =CGPointMake((model.positionX + 3.5)*scale, (model.positionY + 1.5)*scale);
                    CGContextAddLines(contextRef, sPoints, sizeof(sPoints)/sizeof(sPoints[0]));
                    CGContextClosePath(contextRef);
                    CGContextDrawPath(contextRef, kCGPathFillStroke);
                } else if (model.direct == SquareDirect90) {
                    CGContextMoveToPoint(contextRef,(model.positionX + 1.5)*scale, (model.positionY + 3.5)*scale);
                    CGPoint sPoints[3];
                    sPoints[0] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 3.5)*scale);
                    sPoints[1] =CGPointMake((model.positionX + 3.5)*scale, (model.positionY + 5.5)*scale);
                    sPoints[2] =CGPointMake((model.positionX + 3.5)*scale, (model.positionY + 1.5)*scale);
                    CGContextAddLines(contextRef, sPoints, sizeof(sPoints)/sizeof(sPoints[0]));
                    CGContextClosePath(contextRef);
                    CGContextDrawPath(contextRef, kCGPathFillStroke);
                } else if (model.direct == SquareDirect180) {
                    CGContextMoveToPoint(contextRef,(model.positionX + 1.5)*scale, (model.positionY + 1.5)*scale);
                    CGPoint sPoints[3];
                    sPoints[0] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 1.5)*scale);
                    sPoints[1] =CGPointMake((model.positionX + 5.5)*scale, (model.positionY + 1.5)*scale);
                    sPoints[2] =CGPointMake((model.positionX + 3.5)*scale, (model.positionY + 3.5)*scale);
                    CGContextAddLines(contextRef, sPoints, sizeof(sPoints)/sizeof(sPoints[0]));
                    CGContextClosePath(contextRef);
                    CGContextDrawPath(contextRef, kCGPathFillStroke);
                } else if (model.direct == SquareDirect270) {
                    CGContextMoveToPoint(contextRef,(model.positionX + 1.5)*scale, (model.positionY + 1.5)*scale);
                    CGPoint sPoints[3];
                    sPoints[0] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 1.5)*scale);
                    sPoints[1] =CGPointMake((model.positionX + 1.5)*scale, (model.positionY + 5.5)*scale);
                    sPoints[2] =CGPointMake((model.positionX + 3.5)*scale, (model.positionY + 3.5)*scale);
                    CGContextAddLines(contextRef, sPoints, sizeof(sPoints)/sizeof(sPoints[0]));
                    CGContextClosePath(contextRef);
                    CGContextDrawPath(contextRef, kCGPathFillStroke);
                }
            } else if (model.type == SquareTypeDotSquare) {
                CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
                CGContextSetStrokeColorWithColor(contextRef, fillColor.CGColor);
                UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake((model.positionX + 0.5) * scale, (model.positionY + 0.5) * scale) radius:scale/1.6 startAngle:0 endAngle:M_PI * 2.0 clockwise:YES];
                bezierPath.lineCapStyle  = kCGLineCapRound;
                bezierPath.lineJoinStyle = kCGLineJoinRound;
                [bezierPath stroke];
                [bezierPath fill];
            } else if (model.type == SquareTypeWheelSquare) {
                if (model.direct == SquareDirectUp) {
                    CGFloat raduis = 1.5 * scale;
                    CGFloat arcX = (model.positionX + 3)*scale;
                    CGFloat arcY = (model.positionY + 1)*scale;
                    CGContextAddArc(contextRef, arcX, arcY, raduis, 0, M_PI_2*1.7, 0);
                    CGContextStrokePath(contextRef);
                } else if (model.direct == SquareDirect90) {
                    CGFloat raduis = 1.5 * scale;
                    CGFloat arcX = (model.positionX + 1)*scale;
                    CGFloat arcY = (model.positionY + 3)*scale;
                    CGContextAddArc(contextRef, arcX, arcY, raduis, -M_PI_2, M_PI_2*0.7, 0);
                    CGContextStrokePath(contextRef);
                } else if (model.direct == SquareDirect180) {
                    CGFloat raduis = 1.5 * scale;
                    CGFloat arcX = (model.positionX + 3)*scale;
                    CGFloat arcY = (model.positionY + 2.9)*scale;
                    CGContextAddArc(contextRef, arcX, arcY, raduis, -M_PI_2 * 0.3, M_PI_2 * 2, 1);
                    CGContextStrokePath(contextRef);
                } else if (model.direct == SquareDirect270) {
                    CGFloat raduis = 1.5 * scale;
                    CGFloat arcX = (model.positionX + 2.9)*scale;
                    CGFloat arcY = (model.positionY + 3)*scale;
                    CGContextAddArc(contextRef, arcX, arcY, raduis, -M_PI_2, M_PI_2*1.3, 1);
                    CGContextStrokePath(contextRef);
                }
            } else if (model.type == SquareTypeRightAngSquare) {
                if (model.direct == SquareDirectUp) {
                    CGPoint p0 = CGPointMake(model.positionX + 1.5, model.positionY + 1.5);
                    CGPoint p1 = CGPointMake(model.positionX + 2.5 , model.positionY + 1.5);
                    CGPoint p2 = CGPointMake(model.positionX + 2.5 , model.positionY + 2.5);
                    CGContextMoveToPoint(contextRef, p0.x * scale, p0.y * scale);
                    CGContextAddLineToPoint(contextRef, p1.x * scale, p1.y * scale);
                    CGContextAddLineToPoint(contextRef, p2.x * scale, p2.y * scale);
                    CGContextStrokePath(contextRef);
                } else if(model.direct == SquareDirect90) {
                    CGPoint p0 = CGPointMake(model.positionX + 2.5, model.positionY + 1.5);
                    CGPoint p1 = CGPointMake(model.positionX + 1.5 , model.positionY + 1.5);
                    CGPoint p2 = CGPointMake(model.positionX + 1.5 , model.positionY + 2.5);
                    CGContextMoveToPoint(contextRef, p0.x * scale, p0.y * scale);
                    CGContextAddLineToPoint(contextRef, p1.x * scale, p1.y * scale);
                    CGContextAddLineToPoint(contextRef, p2.x * scale, p2.y * scale);
                    CGContextStrokePath(contextRef);
                } else if(model.direct == SquareDirect180) {
                    CGPoint p0 = CGPointMake(model.positionX + 1.5, model.positionY + 1.5);
                    CGPoint p1 = CGPointMake(model.positionX + 1.5 , model.positionY + 2.5);
                    CGPoint p2 = CGPointMake(model.positionX + 2.5 , model.positionY + 2.5);
                    CGContextMoveToPoint(contextRef, p0.x * scale, p0.y * scale);
                    CGContextAddLineToPoint(contextRef, p1.x * scale, p1.y * scale);
                    CGContextAddLineToPoint(contextRef, p2.x * scale, p2.y * scale);
                    CGContextStrokePath(contextRef);
                } else if(model.direct == SquareDirect270) {
                    CGPoint p0 = CGPointMake(model.positionX + 1.5, model.positionY + 2.5);
                    CGPoint p1 = CGPointMake(model.positionX + 2.5 , model.positionY + 2.5);
                    CGPoint p2 = CGPointMake(model.positionX + 2.5 , model.positionY + 1.5);
                    CGContextMoveToPoint(contextRef, p0.x * scale, p0.y * scale);
                    CGContextAddLineToPoint(contextRef, p1.x * scale, p1.y * scale);
                    CGContextAddLineToPoint(contextRef, p2.x * scale, p2.y * scale);
                    CGContextStrokePath(contextRef);
                }
            } else if (model.type == SquareTypeM) {
                if (model.direct == SquareDirectUp) {
                    CGPoint startPoint1 = CGPointMake(model.positionX + 1.5, model.positionY + 1.6);
                    CGPoint controlPoint1 = CGPointMake(model.positionX + 2, model.positionY + 0.9);
                    CGPoint endPoint1 = CGPointMake(model.positionX + 3.5, model.positionY + 2.5);
                    CGContextMoveToPoint(contextRef, startPoint1.x * scale, startPoint1.y * scale);
                    CGContextAddQuadCurveToPoint(contextRef, controlPoint1.x * scale, controlPoint1.y * scale, endPoint1.x * scale, endPoint1.y * scale);
                    CGPoint startPoint2 = CGPointMake(model.positionX + 3.5, model.positionY + 2.5);
                    CGPoint controlPoint2 = CGPointMake(model.positionX + 4.5, model.positionY + 0.9);
                    CGPoint endPoint2 = CGPointMake(model.positionX + 5.5, model.positionY + 1.6);
                    CGContextMoveToPoint(contextRef, startPoint2.x * scale, startPoint2.y * scale);
                    CGContextAddQuadCurveToPoint(contextRef, controlPoint2.x * scale, controlPoint2.y * scale, endPoint2.x * scale, endPoint2.y * scale);
                    CGContextStrokePath(contextRef);
                } else if(model.direct == SquareDirect90) {
                    CGPoint startPoint1 = CGPointMake(model.positionX + 1.6, model.positionY + 1.5);
                    CGPoint controlPoint1 = CGPointMake(model.positionX + 0.9, model.positionY + 2);
                    CGPoint endPoint1 = CGPointMake(model.positionX + 2.5, model.positionY + 3.5);
                    CGContextMoveToPoint(contextRef, startPoint1.x * scale, startPoint1.y * scale);
                    CGContextAddQuadCurveToPoint(contextRef, controlPoint1.x * scale, controlPoint1.y * scale, endPoint1.x * scale, endPoint1.y * scale);
                    CGPoint startPoint2 = CGPointMake(model.positionX + 2.5, model.positionY + 3.5);
                    CGPoint controlPoint2 = CGPointMake(model.positionX + 0.9, model.positionY + 5);
                    CGPoint endPoint2 = CGPointMake(model.positionX + 1.6, model.positionY + 5.5);
                    CGContextMoveToPoint(contextRef, startPoint2.x * scale, startPoint2.y * scale);
                    CGContextAddQuadCurveToPoint(contextRef, controlPoint2.x * scale, controlPoint2.y * scale, endPoint2.x * scale, endPoint2.y * scale);
                    CGContextStrokePath(contextRef);
                } else if(model.direct == SquareDirect180) {
                    CGPoint startPoint1 = CGPointMake(model.positionX + 1.5, model.positionY + 2.4);
                    CGPoint controlPoint1 = CGPointMake(model.positionX + 2, model.positionY + 3.1);
                    CGPoint endPoint1 = CGPointMake(model.positionX + 3.5, model.positionY + 1.5);
                    CGContextMoveToPoint(contextRef, startPoint1.x * scale, startPoint1.y * scale);
                    CGContextAddQuadCurveToPoint(contextRef, controlPoint1.x * scale, controlPoint1.y * scale, endPoint1.x * scale, endPoint1.y * scale);
                    CGPoint startPoint2 = CGPointMake(model.positionX + 3.5, model.positionY + 1.5);
                    CGPoint controlPoint2 = CGPointMake(model.positionX + 4.5, model.positionY + 3.1);
                    CGPoint endPoint2 = CGPointMake(model.positionX + 5.5, model.positionY + 2.4);
                    CGContextMoveToPoint(contextRef, startPoint2.x * scale, startPoint2.y * scale);
                    CGContextAddQuadCurveToPoint(contextRef, controlPoint2.x * scale, controlPoint2.y * scale, endPoint2.x * scale, endPoint2.y * scale);
                    CGContextStrokePath(contextRef);
                } else if(model.direct == SquareDirect270) {
                    CGPoint startPoint1 = CGPointMake(model.positionX + 2.4, model.positionY + 1.5);
                    CGPoint controlPoint1 = CGPointMake(model.positionX + 3.1, model.positionY + 2);
                    CGPoint endPoint1 = CGPointMake(model.positionX + 1.5, model.positionY + 3.5);
                    CGContextMoveToPoint(contextRef, startPoint1.x * scale, startPoint1.y * scale);
                    CGContextAddQuadCurveToPoint(contextRef, controlPoint1.x * scale, controlPoint1.y * scale, endPoint1.x * scale, endPoint1.y * scale);
                    CGPoint startPoint2 = CGPointMake(model.positionX + 1.5, model.positionY + 3.5);
                    CGPoint controlPoint2 = CGPointMake(model.positionX + 3.1, model.positionY + 5);
                    CGPoint endPoint2 = CGPointMake(model.positionX + 2.4, model.positionY + 5.5);
                    CGContextMoveToPoint(contextRef, startPoint2.x * scale, startPoint2.y * scale);
                    CGContextAddQuadCurveToPoint(contextRef, controlPoint2.x * scale, controlPoint2.y * scale, endPoint2.x * scale, endPoint2.y * scale);
                    CGContextStrokePath(contextRef);
                }
            } else if (model.type == SquareTypeObliqueLeft) {
               if (model.direct == SquareDirectUp) {
                   CGPoint startPoint2 = CGPointMake(model.positionX + 1.5, model.positionY + 1.5);
                   CGPoint controlPoint2 = CGPointMake(model.positionX + 2, model.positionY + 1.8);
                   CGPoint endPoint2 = CGPointMake(model.positionX + 2.5, model.positionY + 2.5);
                   CGContextMoveToPoint(contextRef, startPoint2.x * scale, startPoint2.y * scale);
                   CGContextAddQuadCurveToPoint(contextRef, controlPoint2.x * scale, controlPoint2.y * scale, endPoint2.x * scale, endPoint2.y * scale);
                   CGContextAddLineToPoint(contextRef, (model.positionX + 2.5)*scale,  (model.positionY + 3.5)*scale);
                   CGContextStrokePath(contextRef);
               } else if(model.direct == SquareDirect90) {
                   CGPoint startPoint2 = CGPointMake(model.positionX + 1.5, model.positionY + 2.5);
                   CGPoint controlPoint2 = CGPointMake(model.positionX + 1.5, model.positionY + 2);
                   CGPoint endPoint2 = CGPointMake(model.positionX + 2.5, model.positionY + 1.5);
                   CGContextMoveToPoint(contextRef, startPoint2.x * scale, startPoint2.y * scale);
                   CGContextAddQuadCurveToPoint(contextRef, controlPoint2.x * scale, controlPoint2.y * scale, endPoint2.x * scale, endPoint2.y * scale);
                   CGContextAddLineToPoint(contextRef, (model.positionX + 3.5)*scale,  (model.positionY + 1.5)*scale);
                   CGContextStrokePath(contextRef);
               } else if(model.direct == SquareDirect180) {
                   CGPoint startPoint2 = CGPointMake(model.positionX + 2.5, model.positionY + 3.5);
                   CGPoint controlPoint2 = CGPointMake(model.positionX + 2, model.positionY + 3.2);
                   CGPoint endPoint2 = CGPointMake(model.positionX + 1.5, model.positionY + 2.5);
                   CGContextMoveToPoint(contextRef, startPoint2.x * scale, startPoint2.y * scale);
                   CGContextAddQuadCurveToPoint(contextRef, controlPoint2.x * scale, controlPoint2.y * scale, endPoint2.x * scale, endPoint2.y * scale);
                   CGContextAddLineToPoint(contextRef, (model.positionX + 1.5)*scale,  (model.positionY + 1.5)*scale);
                   CGContextStrokePath(contextRef);
               } else if(model.direct == SquareDirect270) {
                   CGPoint startPoint2 = CGPointMake(model.positionX + 3.5, model.positionY + 1.5);
                   CGPoint controlPoint2 = CGPointMake(model.positionX + 3.2, model.positionY + 2);
                   CGPoint endPoint2 = CGPointMake(model.positionX + 2.5, model.positionY + 2.5);
                   CGContextMoveToPoint(contextRef, startPoint2.x * scale, startPoint2.y * scale);
                   CGContextAddQuadCurveToPoint(contextRef, controlPoint2.x * scale, controlPoint2.y * scale, endPoint2.x * scale, endPoint2.y * scale);
                   CGContextAddLineToPoint(contextRef, (model.positionX + 1.5)*scale,  (model.positionY + 2.5)*scale);
                   CGContextStrokePath(contextRef);
               }
           } else if (model.type == SquareTypeObliqueRight) {
               if (model.direct == SquareDirectUp) {
                   CGPoint startPoint = CGPointMake(model.positionX + 2.5, model.positionY + 1.5);
                   CGPoint controlPoint = CGPointMake(model.positionX + 2, model.positionY + 1.8);
                   CGPoint endPoint = CGPointMake(model.positionX + 1.5, model.positionY + 2.5);
                   CGContextMoveToPoint(contextRef, startPoint.x * scale, startPoint.y * scale);
                   CGContextAddQuadCurveToPoint(contextRef, controlPoint.x * scale, controlPoint.y * scale, endPoint.x * scale, endPoint.y * scale);
                   CGContextAddLineToPoint(contextRef, (model.positionX + 1.5)*scale,  (model.positionY + 3.5)*scale);
                   CGContextStrokePath(contextRef);
               } else if(model.direct == SquareDirect90) {
                   CGPoint startPoint = CGPointMake(model.positionX + 1.5, model.positionY + 1.5);
                   CGPoint controlPoint = CGPointMake(model.positionX + 1.8, model.positionY + 2);
                   CGPoint endPoint = CGPointMake(model.positionX + 2.5, model.positionY + 2.5);
                   CGContextMoveToPoint(contextRef, startPoint.x * scale, startPoint.y * scale);
                   CGContextAddQuadCurveToPoint(contextRef, controlPoint.x * scale, controlPoint.y * scale, endPoint.x * scale, endPoint.y * scale);
                   CGContextAddLineToPoint(contextRef, (model.positionX + 3.5)*scale,  (model.positionY + 2.5)*scale);
                   CGContextStrokePath(contextRef);
               } else if(model.direct == SquareDirect180) {
                   CGPoint startPoint = CGPointMake(model.positionX + 1.5, model.positionY + 3.5);
                   CGPoint controlPoint = CGPointMake(model.positionX + 2, model.positionY + 3.2);
                   CGPoint endPoint = CGPointMake(model.positionX + 2.5, model.positionY + 2.5);
                   CGContextMoveToPoint(contextRef, startPoint.x * scale, startPoint.y * scale);
                   CGContextAddQuadCurveToPoint(contextRef, controlPoint.x * scale, controlPoint.y * scale, endPoint.x * scale, endPoint.y * scale);
                   CGContextAddLineToPoint(contextRef, (model.positionX + 2.5)*scale,  (model.positionY + 1.5)*scale);
                   CGContextStrokePath(contextRef);
               } else if(model.direct == SquareDirect270) {
                   CGPoint startPoint = CGPointMake(model.positionX + 3.5, model.positionY + 2.5);
                   CGPoint controlPoint = CGPointMake(model.positionX + 3.2, model.positionY + 2);
                   CGPoint endPoint = CGPointMake(model.positionX + 2.5, model.positionY + 1.5);
                   CGContextMoveToPoint(contextRef, startPoint.x * scale, startPoint.y * scale);
                   CGContextAddQuadCurveToPoint(contextRef, controlPoint.x * scale, controlPoint.y * scale, endPoint.x * scale, endPoint.y * scale);
                   CGContextAddLineToPoint(contextRef, (model.positionX + 1.5)*scale,  (model.positionY + 1.5)*scale);
                   CGContextStrokePath(contextRef);
               }
           } else if (model.type == SquareTypeDotX) {
               if (model.direct == SquareDirectUp) {
                   CGPoint startPoint1 = CGPointMake(model.positionX + 0.7, model.positionY + 0.7);
                   CGPoint endPoint1 = CGPointMake(model.positionX + 3.3, model.positionY + 3.3);
                   CGPoint startPoint2 = CGPointMake(model.positionX + 3.3, model.positionY + 0.7);
                   CGPoint endPoint2 = CGPointMake(model.positionX + 0.7, model.positionY + 3.3);
                   CGContextMoveToPoint(contextRef, startPoint1.x * scale, startPoint1.y * scale);
                   CGContextAddLineToPoint(contextRef, endPoint1.x * scale, endPoint1.y * scale);
                   CGContextMoveToPoint(contextRef, startPoint2.x * scale, startPoint2.y * scale);
                   CGContextAddLineToPoint(contextRef, endPoint2.x * scale,  endPoint2.y * scale);
                   CGContextStrokePath(contextRef);
                }
            } else if (model.type == SquareTypeDotBig) {
               if (model.direct == SquareDirectUp) {
                   UIBezierPath *bezierPath = nil;
                   CGFloat param = 2.3;
                   CGRect rect = CGRectMake((model.positionX + 0.85) * scale, (model.positionY + 0.85) * scale, param * scale, param * scale);
                   CGFloat radius = param * scale / 2;
                   bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
                   bezierPath.lineCapStyle  = kCGLineCapRound;
                   bezierPath.lineJoinStyle = kCGLineJoinRound; // kCGLineCapRound;
                   [bezierPath stroke];
                   [bezierPath fill];
                   CGContextStrokePath(contextRef);
                }
            }
        }
    }
}
@end
