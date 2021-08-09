//
//  DotBitSquareModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/6/8.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "DotBitSquareModel.h"

@implementation DotBitSquareModel

- (instancetype)init {
    if (self = [super init]) {
        self.type = SquareTypeDotBig;
    }
    return self;
}

+ (PixelMatrix *)compareMitrix {
    PixelMatrix *mitrix = [[PixelMatrix alloc] initWithRow:4 col:4];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:1];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:2];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:1];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:2];
    [mitrix setCompareIgnore:true row:0 col:0];
    [mitrix setCompareIgnore:true row:0 col:3];
    [mitrix setCompareIgnore:true row:3 col:0];
    [mitrix setCompareIgnore:true row:3 col:3];
    return mitrix;
}

+ (NSArray<DotBitSquareModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j {
    NSMutableArray *resultArray = [NSMutableArray array];
    PixelMatrix *compareUpMatrix = [DotBitSquareModel compareMitrix];
    
    PixelMatrix *subMatrixUp = [mitrix subMatrixWithRow:i col:j offsetRow:compareUpMatrix.row offsetCol:compareUpMatrix.col];
    if (subMatrixUp != nil && [subMatrixUp compareWithMatrix: compareUpMatrix]) {
        DotBitSquareModel *model = [DotBitSquareModel new];
        model.direct = SquareDirectUp;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        
        PixelModel *modelLeftUp = [subMatrixUp valueAtRow:0 col:0];
        PixelModel *modelLeftDown = [subMatrixUp valueAtRow:(compareUpMatrix.row - 1) col:0];
        PixelModel *modelRightUp = [subMatrixUp valueAtRow:0 col:(compareUpMatrix.col -1)];
        PixelModel *modelRightDown = [subMatrixUp valueAtRow:(compareUpMatrix.row -1) col:(compareUpMatrix.col -1)];
        if (modelLeftUp.alpha > 0 && modelLeftDown.alpha > 0 && modelRightUp.alpha > 0 && modelRightDown.alpha > 0) {
            model.type = SquareTypeDotX;
        }
        
        [resultArray addObject:model];
    }
    return [resultArray copy];
}

@end
