//
//  MSquareModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/6/3.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "MSquareModel.h"

@implementation MSquareModel

- (instancetype)init {
    if (self = [super init]) {
        self.type = SquareTypeM;
    }
    return self;
}

+ (PixelMatrix *)compareMitrix {
    PixelMatrix *mitrix = [[PixelMatrix alloc] initWithRow:4 col:7];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:1];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:2];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:4];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:5];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:3];
    [mitrix setCompareIgnore:true row:0 col:0];
    [mitrix setCompareIgnore:true row:0 col:6];
    [mitrix setCompareIgnore:true row:2 col:0];
    [mitrix setCompareIgnore:true row:2 col:6];
    [mitrix setCompareIgnore:true row:3 col:0];
    [mitrix setCompareIgnore:true row:3 col:1];
    [mitrix setCompareIgnore:true row:3 col:2];
    [mitrix setCompareIgnore:true row:3 col:3];
    [mitrix setCompareIgnore:true row:3 col:4];
    [mitrix setCompareIgnore:true row:3 col:5];
    [mitrix setCompareIgnore:true row:3 col:6];
    return mitrix;
}

+ (NSArray<MSquareModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j {
    NSMutableArray *resultArray = [NSMutableArray array];
    PixelMatrix *compareUpMatrix = [MSquareModel compareMitrix];
    PixelMatrix *compare90Matrix = [compareUpMatrix transferLeft];
    PixelMatrix *compare180Matrix = [compare90Matrix transferLeft];
    PixelMatrix *compare270Matrix = [compare180Matrix transferLeft];
    
    PixelMatrix *subMatrixUp = [mitrix subMatrixWithRow:i col:j offsetRow:compareUpMatrix.row offsetCol:compareUpMatrix.col];
    PixelMatrix *subMatrix90 = [mitrix subMatrixWithRow:i col:j offsetRow:compare90Matrix.row offsetCol:compare90Matrix.col];
    if ([subMatrixUp compareWithMatrix: compareUpMatrix]) {
        MSquareModel *model = [MSquareModel new];
        model.direct = SquareDirectUp;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrix90 compareWithMatrix: compare90Matrix]) {
        MSquareModel *model = [MSquareModel new];
        model.direct = SquareDirect90;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrixUp compareWithMatrix: compare180Matrix]) {
        MSquareModel *model = [MSquareModel new];
        model.direct = SquareDirect180;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrix90 compareWithMatrix: compare270Matrix]) {
        MSquareModel *model = [MSquareModel new];
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
