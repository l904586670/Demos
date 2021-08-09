//
//  WheelSquareRightModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/29.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "WheelSquareRightModel.h"

@implementation WheelSquareRightModel

- (instancetype)init {
    if (self = [super init]) {
        self.type = SquareTypeWheelSquare;
    }
    return self;
}

+ (PixelMatrix *)compareMitrix {
    PixelMatrix *mitrix = [[PixelMatrix alloc] initWithRow:4 col:6];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:1];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:4];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:2];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:3];
    [mitrix setCompareIgnore:true row:0 col:0];
    [mitrix setCompareIgnore:true row:0 col:1];
    [mitrix setCompareIgnore:true row:0 col:5];
    [mitrix setCompareIgnore:true row:3 col:0];
    [mitrix setCompareIgnore:true row:3 col:0];
    [mitrix setCompareIgnore:true row:3 col:5];
    return mitrix;
}

+ (NSArray<WheelSquareRightModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j {
    NSMutableArray *resultArray = [NSMutableArray array];
    PixelMatrix *compareUpMatrix = [WheelSquareRightModel compareMitrix];
    PixelMatrix *compareMatrix90 = [compareUpMatrix transferLeft];
    PixelMatrix *compareMatrix180 = [compareMatrix90 transferLeft];
    PixelMatrix *compareMatrix270 = [compareMatrix180 transferLeft];
    
    PixelMatrix *subMatrixUp = [mitrix subMatrixWithRow:i col:j offsetRow:compareUpMatrix.row offsetCol:compareUpMatrix.col];
    PixelMatrix *subMatrix90 = [mitrix subMatrixWithRow:i col:j offsetRow:compareMatrix90.row offsetCol:compareMatrix90.col];
    if ([subMatrixUp compareWithMatrix: compareUpMatrix]) {
        WheelSquareRightModel *model = [WheelSquareRightModel new];
        model.direct = SquareDirectUp;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    if ([subMatrix90 compareWithMatrix: compareMatrix90]) {
        WheelSquareRightModel *model = [WheelSquareRightModel new];
        model.direct = SquareDirect90;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    if ([subMatrixUp compareWithMatrix: compareMatrix180]) {
        WheelSquareRightModel *model = [WheelSquareRightModel new];
        model.direct = SquareDirect180;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    if ([subMatrix90 compareWithMatrix: compareMatrix270]) {
        WheelSquareRightModel *model = [WheelSquareRightModel new];
        model.direct = SquareDirect270;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    return [resultArray copy];
}

@end
