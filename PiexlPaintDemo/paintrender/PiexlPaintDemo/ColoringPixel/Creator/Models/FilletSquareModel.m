//
//  FilletSquareModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/28.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "FilletSquareModel.h"
#import "PixelMatrix+Transfer.h"

@implementation FilletSquareModel
- (instancetype)init {
    if (self = [super init]) {
        self.type = SquareTypeFillet;
    }
    return self;
}

+ (PixelMatrix *)compareMitrix {
    PixelMatrix *mitrix = [[PixelMatrix alloc] initWithRow:5 col:5];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:2];
    [mitrix setValue:[PixelModel alphaTrueModel] row:1 col:3];
    [mitrix setValue:[PixelModel alphaTrueModel] row:2 col:1];
    [mitrix setValue:[PixelModel alphaTrueModel] row:3 col:1];
    [mitrix setCompareIgnore:true row:0 col:0];
    [mitrix setCompareIgnore:true row:0 col:1];
    [mitrix setCompareIgnore:true row:0 col:4];
    [mitrix setCompareIgnore:true row:1 col:0];
    [mitrix setCompareIgnore:true row:1 col:4];
    [mitrix setCompareIgnore:true row:2 col:3];
    [mitrix setCompareIgnore:true row:2 col:4];
    [mitrix setCompareIgnore:true row:3 col:2];
    [mitrix setCompareIgnore:true row:3 col:3];
    [mitrix setCompareIgnore:true row:3 col:4];
    [mitrix setCompareIgnore:true row:4 col:0];
    [mitrix setCompareIgnore:true row:4 col:1];
    [mitrix setCompareIgnore:true row:4 col:2];
    [mitrix setCompareIgnore:true row:4 col:3];
    [mitrix setCompareIgnore:true row:4 col:4];
    return mitrix;
}

+ (NSArray<FilletSquareModel *> *)checkWithMitrix:(PixelMatrix *)mitrix model:(PixelModel *)pixelModel row:(NSInteger)i col:(NSInteger)j {
    NSMutableArray *resultArray = [NSMutableArray array];
    PixelMatrix *compareUpMatrix = [FilletSquareModel compareMitrix];
    PixelMatrix *compareMatrix90 = [compareUpMatrix transferLeft];
    PixelMatrix *compareMatrix180 = [compareMatrix90 transferLeft];
    PixelMatrix *compareMatrix270 = [compareMatrix180 transferLeft];
    
    PixelMatrix *subMatrix = [mitrix subMatrixWithRow:i col:j offsetRow:compareUpMatrix.row offsetCol:compareUpMatrix.col];
    if ([subMatrix compareWithMatrix: compareUpMatrix]) {
        FilletSquareModel *filletModel = [FilletSquareModel new];
        filletModel.direct = SquareDirectUp;
        filletModel.positionX = j;
        filletModel.positionY = i;
        filletModel.width = compareUpMatrix.col;
        filletModel.height = compareUpMatrix.row;
        [resultArray addObject:filletModel];
    }
    
    if ([subMatrix compareWithMatrix:compareMatrix90]) {
        FilletSquareModel *filletModel = [FilletSquareModel new];
        filletModel.direct = SquareDirect90;
        filletModel.positionX = j;
        filletModel.positionY = i;
        filletModel.width = compareMatrix90.col;
        filletModel.height = compareMatrix90.row;
        [resultArray addObject:filletModel];
    }
    
    if ([subMatrix compareWithMatrix:compareMatrix180]) {
        FilletSquareModel *filletModel = [FilletSquareModel new];
        filletModel.direct = SquareDirect180;
        filletModel.positionX = j;
        filletModel.positionY = i;
        filletModel.width = compareMatrix180.col;
        filletModel.height = compareMatrix180.row;
        [resultArray addObject:filletModel];
    }
    
    if ([subMatrix compareWithMatrix:compareMatrix270]) {
        FilletSquareModel *filletModel = [FilletSquareModel new];
        filletModel.direct = SquareDirect270;
        filletModel.positionX = j;
        filletModel.positionY = i;
        filletModel.width = compareMatrix270.col;
        filletModel.height = compareMatrix270.row;
        [resultArray addObject:filletModel];
    }
    return [resultArray copy];
}
@end

