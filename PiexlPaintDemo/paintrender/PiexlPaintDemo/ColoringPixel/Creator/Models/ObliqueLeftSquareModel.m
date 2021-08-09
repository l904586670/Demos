//
//  ObliqueLeftSquareModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/6/4.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "ObliqueLeftSquareModel.h"

@implementation ObliqueLeftSquareModel

- (instancetype)init {
    if (self = [super init]) {
        self.type = SquareTypeObliqueLeft;
    }
    return self;
}

+ (PixelMatrix *)compareMitrix {
    PixelMatrix *mitrix = [[PixelMatrix alloc] initWithRow:5 col:4];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:1];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:2];
    [mitrix setValue:[PixelModel alphaTrueModel] row:3 col:2];
    [mitrix setCompareIgnore:true row:0 col:0];
    [mitrix setCompareIgnore:true row:0 col:1];
    [mitrix setCompareIgnore:true row:0 col:2];
    [mitrix setCompareIgnore:true row:0 col:3];
    [mitrix setCompareIgnore:true row:1 col:3];
    [mitrix setCompareIgnore:true row:2 col:0];
    [mitrix setCompareIgnore:true row:3 col:0];
    [mitrix setCompareIgnore:true row:4 col:0];
    [mitrix setCompareIgnore:true row:4 col:1];
    [mitrix setCompareIgnore:true row:4 col:2];
    [mitrix setCompareIgnore:true row:4 col:3];
    return mitrix;
}

+ (NSArray<ObliqueLeftSquareModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j {
    NSMutableArray *resultArray = [NSMutableArray array];
    PixelMatrix *compareUpMatrix = [ObliqueLeftSquareModel compareMitrix];
    PixelMatrix *compare90Matrix = [compareUpMatrix transferLeft];
    PixelMatrix *compare180Matrix = [compare90Matrix transferLeft];
    PixelMatrix *compare270Matrix = [compare180Matrix transferLeft];
    
    PixelMatrix *subMatrixUp = [mitrix subMatrixWithRow:i col:j offsetRow:compareUpMatrix.row offsetCol:compareUpMatrix.col];
    PixelMatrix *subMatrix90 = [mitrix subMatrixWithRow:i col:j offsetRow:compare90Matrix.row offsetCol:compare90Matrix.col];
    if ([subMatrixUp compareWithMatrix: compareUpMatrix]) {
        ObliqueLeftSquareModel *model = [ObliqueLeftSquareModel new];
        model.direct = SquareDirectUp;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrix90 compareWithMatrix: compare90Matrix]) {
        ObliqueLeftSquareModel *model = [ObliqueLeftSquareModel new];
        model.direct = SquareDirect90;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrixUp compareWithMatrix: compare180Matrix]) {
        ObliqueLeftSquareModel *model = [ObliqueLeftSquareModel new];
        model.direct = SquareDirect180;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrix90 compareWithMatrix: compare270Matrix]) {
        ObliqueLeftSquareModel *model = [ObliqueLeftSquareModel new];
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
