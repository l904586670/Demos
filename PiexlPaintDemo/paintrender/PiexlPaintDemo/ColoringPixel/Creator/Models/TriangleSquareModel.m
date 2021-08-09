//
//  NSTriangleModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/27.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "TriangleSquareModel.h"

@implementation TriangleSquareModel
- (instancetype)init {
    if (self = [super init]) {
        self.type = SquareTypeTriangle;
    }
    return self;
}

+ (PixelMatrix *)compareMitrix {
    PixelMatrix *mitrix = [[PixelMatrix alloc] initWithRow:5 col:7];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:3];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:2];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:3];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:4];
    [mitrix setValue:[PixelModel alphaTrueModel] row:3 col:1];
    [mitrix setValue:[PixelModel alphaTrueModel] row:3 col:2];
    [mitrix setValue:[PixelModel alphaTrueModel] row:3 col:3];
    [mitrix setValue:[PixelModel alphaTrueModel] row:3 col:4];
    [mitrix setValue:[PixelModel alphaTrueModel] row:3 col:5];
    [mitrix setCompareIgnore:YES row:0 col:0];
    [mitrix setCompareIgnore:YES row:0 col:1];
    [mitrix setCompareIgnore:YES row:0 col:2];
    [mitrix setCompareIgnore:YES row:0 col:4];
    [mitrix setCompareIgnore:YES row:0 col:5];
    [mitrix setCompareIgnore:YES row:0 col:6];
    [mitrix setCompareIgnore:YES row:1 col:0];
    [mitrix setCompareIgnore:YES row:1 col:1];
    [mitrix setCompareIgnore:YES row:1 col:5];
    [mitrix setCompareIgnore:YES row:1 col:6];
    [mitrix setCompareIgnore:YES row:2 col:0];
    [mitrix setCompareIgnore:YES row:2 col:6];
    [mitrix setCompareIgnore:YES row:4 col:0];
    [mitrix setCompareIgnore:YES row:4 col:1];
    [mitrix setCompareIgnore:YES row:4 col:2];
    [mitrix setCompareIgnore:YES row:4 col:3];
    [mitrix setCompareIgnore:YES row:4 col:4];
    [mitrix setCompareIgnore:YES row:4 col:5];
    [mitrix setCompareIgnore:YES row:4 col:6];
    return mitrix;
}

+ (NSArray<TriangleSquareModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j {
    NSMutableArray *result = [NSMutableArray array];
    PixelMatrix *compareUpMatrix = [TriangleSquareModel compareMitrix];
    PixelMatrix *compareMatrix90 = [compareUpMatrix transferLeft];
    PixelMatrix *compareMatrix180 = [compareMatrix90 transferLeft];
    PixelMatrix *compareMatrix270 = [compareMatrix180 transferLeft];
    
    PixelMatrix *subMatrix = [mitrix subMatrixWithRow:i col:j offsetRow:compareUpMatrix.row offsetCol:compareUpMatrix.col];
    PixelMatrix *subMatrix90 = [mitrix subMatrixWithRow:i col:j offsetRow:compareMatrix90.row offsetCol:compareMatrix90.col];
    if ([subMatrix compareWithMatrix: compareUpMatrix]) {
        TriangleSquareModel *triangleModel = [TriangleSquareModel new];
        triangleModel.direct = SquareDirectUp;
        triangleModel.positionX = j;
        triangleModel.positionY = i;
        triangleModel.width = compareUpMatrix.col;
        triangleModel.height = compareUpMatrix.row;
        [result addObject:triangleModel];
    }
    
    if ([subMatrix90 compareWithMatrix: compareMatrix90]) {
        TriangleSquareModel *triangleModel = [TriangleSquareModel new];
        triangleModel.direct = SquareDirect90;
        triangleModel.positionX = j;
        triangleModel.positionY = i;
        triangleModel.width = compareMatrix90.col;
        triangleModel.height = compareMatrix90.row;
        [result addObject:triangleModel];
    }
    
    if ([subMatrix compareWithMatrix: compareMatrix180]) {
        TriangleSquareModel *triangleModel = [TriangleSquareModel new];
        triangleModel.direct = SquareDirect180;
        triangleModel.positionX = j;
        triangleModel.positionY = i;
        triangleModel.width = compareMatrix180.col;
        triangleModel.height = compareMatrix180.row;
        [result addObject:triangleModel];
    }
    
    if ([subMatrix90 compareWithMatrix: compareMatrix270]) {
        TriangleSquareModel *triangleModel = [TriangleSquareModel new];
        triangleModel.direct = SquareDirect270;
        triangleModel.positionX = j;
        triangleModel.positionY = i;
        triangleModel.width = compareMatrix270.col;
        triangleModel.height = compareMatrix270.row;
        [result addObject:triangleModel];
    }
    return result;
}
@end
