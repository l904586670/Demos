//
//  RightAngSquareModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/29.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "RightAngSquareModel.h"

@implementation RightAngSquareModel

- (instancetype)init {
    if (self = [super init]) {
        self.type = SquareTypeRightAngSquare;
    }
    return self;
}

+ (PixelMatrix *)compareMitrix {
    PixelMatrix *mitrix = [[PixelMatrix alloc] initWithRow:4 col:4];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:1];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:2];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:2];
    [mitrix setCompareIgnore:true row:1 col:0];
    [mitrix setCompareIgnore:true row:2 col:0];
    [mitrix setCompareIgnore:true row:3 col:0];
    [mitrix setCompareIgnore:true row:3 col:1];
    [mitrix setCompareIgnore:true row:3 col:2];
    return mitrix;
}

+ (NSArray<RightAngSquareModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j {
    NSMutableArray *resultArray = [NSMutableArray array];
    PixelMatrix *compareUpMatrix = [RightAngSquareModel compareMitrix];
    PixelMatrix *compare90Matrix = [compareUpMatrix transferLeft];
    PixelMatrix *compare180Matrix = [compare90Matrix transferLeft];
    PixelMatrix *compare270Matrix = [compare180Matrix transferLeft];
    
    PixelMatrix *subMatrix = [mitrix subMatrixWithRow:i col:j offsetRow:compareUpMatrix.row offsetCol:compareUpMatrix.col];
    if ([subMatrix compareWithMatrix: compareUpMatrix]) {
        RightAngSquareModel *model = [RightAngSquareModel new];
        model.direct = SquareDirectUp;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrix compareWithMatrix: compare90Matrix]) {
        RightAngSquareModel *model = [RightAngSquareModel new];
        model.direct = SquareDirect90;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrix compareWithMatrix: compare180Matrix]) {
        RightAngSquareModel *model = [RightAngSquareModel new];
        model.direct = SquareDirect180;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrix compareWithMatrix: compare270Matrix]) {
        RightAngSquareModel *model = [RightAngSquareModel new];
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
