//
//  LineSquareModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/28.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "LineSquareModel.h"
#import "PixelMatrix+Transfer.h"

@implementation LineSquareModel
- (instancetype)init {
    if (self = [super init]) {
        self.type = SquareTypeSlantLine;
    }
    return self;
}

+ (PixelMatrix *)compareMitrix {
    PixelMatrix *mitrix = [[PixelMatrix alloc] initWithRow:4 col:4];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:1];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:2];
    [mitrix setCompareIgnore:true row:0 col:0];
    [mitrix setCompareIgnore:true row:0 col:1];
    [mitrix setCompareIgnore:true row:0 col:3];
    [mitrix setCompareIgnore:true row:1 col:0];
    [mitrix setCompareIgnore:true row:2 col:3];
    [mitrix setCompareIgnore:true row:3 col:0];
    [mitrix setCompareIgnore:true row:3 col:2];
    [mitrix setCompareIgnore:true row:3 col:3];
    return mitrix;
}

+ (NSArray<LineSquareModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j {
    NSMutableArray *resultArray = [NSMutableArray array];
    PixelMatrix *compareUpMatrix = [LineSquareModel compareMitrix];
    PixelMatrix *compareMatrix90 = [compareUpMatrix transferLeft];
//    PixelMatrix *compareMatrix180 = [compareMatrix90 transferLeft];
//    PixelMatrix *compareMatrix270 = [compareMatrix180 transferLeft];
    
    PixelMatrix *subMatrix = [mitrix subMatrixWithRow:i col:j offsetRow:compareUpMatrix.row offsetCol:compareUpMatrix.col];
    if ([subMatrix compareWithMatrix: compareUpMatrix]) {
        LineSquareModel *model = [LineSquareModel new];
        model.direct = SquareDirectUp;
        model.positionX = j;
        model.positionY = i;
        model.width = compareUpMatrix.col;
        model.height = compareUpMatrix.row;
        [resultArray addObject:model];
    }
    
    if ([subMatrix compareWithMatrix:compareMatrix90]) {
        LineSquareModel *model = [LineSquareModel new];
        model.direct = SquareDirect90;
        model.positionX = j;
        model.positionY = i;
        model.width = compareMatrix90.col;
        model.height = compareMatrix90.row;
        [resultArray addObject:model];
    }
    
//    if ([subMatrix compareWithMatrix:compareMatrix180]) {
//        LineSquareModel *model = [LineSquareModel new];
//        model.direct = SquareDirect180;
//        model.positionX = j;
//        model.positionY = i;
//        model.width = compareMatrix180.col;
//        model.height = compareMatrix180.row;
//        [resultArray addObject:model];
//    }
//
//    if ([subMatrix compareWithMatrix:compareMatrix270]) {
//        LineSquareModel *model = [LineSquareModel new];
//        model.direct = SquareDirect270;
//        model.positionX = j;
//        model.positionY = i;
//        model.width = compareMatrix270.col;
//        model.height = compareMatrix270.row;
//        [resultArray addObject:model];
//    }
    return [resultArray copy];
}
@end
