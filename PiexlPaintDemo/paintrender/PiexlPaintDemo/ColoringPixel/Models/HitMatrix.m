//
//  HitMatrix.m
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "HitMatrix.h"
@interface HitMatrix ()

@property (nonatomic, strong) NSMutableArray *valueArray;

@end

@implementation HitMatrix

- (instancetype)init {
    if (self = [super init]) {
        _row = 0;
        _col = 0;
    }
    return self;
}

- (instancetype)initWithPixelMatrix:(PixelMatrix *)matrix {
    if (self = [super init]) {
        _row = matrix.row;
        _col = matrix.col;
        
        _valueArray = [[NSMutableArray alloc] initWithCapacity:matrix.row];
        for (NSInteger r = 0; r < self.row; ++r) {
            [_valueArray addObject:[[NSMutableArray alloc] initWithCapacity:matrix.col]];
            for (NSInteger c = 0; c < self.col; ++c) {
                HitModel *hModel = [[HitModel alloc] init];
                PixelModel *pModel = [matrix valueAtRow:r col:c];
                if (pModel.alpha > 0) {
                    hModel.isDraw = YES;
                } else {
                    hModel.isDraw = NO;
                }
                _valueArray[r][c] = hModel;
            }
        }
    }
    return self;
}

#pragma mark - Valid

- (BOOL)invalid:(CGPoint)position {
    return [self invalidRow:position.y] || [self invalidCol:position.x];
}

- (BOOL)invalidRow:(NSInteger)r {
    return ((r < 0) || (r >= _row));
}

- (BOOL)invalidCol:(NSInteger)c {
    return ((c < 0) || (c >= _col));
}

#pragma mark - Set

- (void)addValue:(SquareType)value row:(NSInteger)r col:(NSInteger)c {
    if ([self invalidRow:r] || [self invalidCol:c]) {
        return;
    }
    HitModel *model = _valueArray[r][c];
    [model.hitTypeArray addObject:[[NSNumber alloc] initWithInteger:value]];
}

#pragma mark - Get

- (HitModel*)valueAtRow:(NSInteger)r col:(NSInteger)c {
    if ([self invalidRow:r] || [self invalidCol:c]) {
        return nil;
    }
    
    return _valueArray[r][c];
}

- (NSArray<DotSquareModel *> *)unHitDotArray {
    NSMutableArray *unHitArray = [NSMutableArray array];
    for (NSInteger r = 0; r < self.row; ++r) {
        for (NSInteger c = 0; c < self.col; ++c) {
            HitModel *hModel = [self valueAtRow:r col:c];
            if (hModel.hitTypeArray.count <= 0 && hModel.isDraw) {
                DotSquareModel *dotModel = [[DotSquareModel alloc] init];
                dotModel.positionX = c;
                dotModel.positionY = r;
                [unHitArray addObject:dotModel];
            }
        }
    }
    return [unHitArray copy];
}


- (void)updateHitTypeWithSlantSquare:(NSArray<SlantSquareModel *> *)slantArray {
    if (slantArray.count > 0) {
        for (SlantSquareModel *model in slantArray) {
            PixelMatrix *compare = nil;
            if ([model isKindOfClass:[FilletSquareModel class]]) {
                if (model.direct == SquareDirectUp) {
                    compare = [FilletSquareModel compareMitrix];
                } else if (model.direct == SquareDirect90) {
                    compare = [[FilletSquareModel compareMitrix] transferLeft];
                } else if (model.direct == SquareDirect180) {
                    compare = [[[FilletSquareModel compareMitrix] transferLeft] transferLeft];
                } else if (model.direct == SquareDirect270) {
                    compare = [[[[FilletSquareModel compareMitrix] transferLeft] transferLeft] transferLeft];
                }
            } else if ([model isKindOfClass:[WheelSquareLeftModel class]]) {
                if (model.direct == SquareDirectUp) {
                    compare = [WheelSquareLeftModel compareMitrix];
                } else if (model.direct == SquareDirect90) {
                    compare = [[WheelSquareLeftModel compareMitrix] transferLeft];
                } else if (model.direct == SquareDirect180) {
                    compare = [[[WheelSquareLeftModel compareMitrix] transferLeft] transferLeft];
                } else if (model.direct == SquareDirect270) {
                    compare = [[[[WheelSquareLeftModel compareMitrix] transferLeft] transferLeft] transferLeft];
                }
            } else if ([model isKindOfClass:[DotBitSquareModel class]]) {
                if (model.direct == SquareDirectUp) {
                    compare = [DotBitSquareModel compareMitrix];
                }
            } else if ([model isKindOfClass:[LineSquareModel class]]) {
                if (model.direct == SquareDirectUp) {
                    compare = [LineSquareModel compareMitrix];
                } else if (model.direct == SquareDirect90) {
                    compare = [[LineSquareModel compareMitrix] transferLeft];
                }
            } else if ([model isKindOfClass:[RightAngSquareModel class]]) {
                if (model.direct == SquareDirectUp) {
                    compare = [RightAngSquareModel compareMitrix];
                } else if (model.direct == SquareDirect90) {
                    compare = [[RightAngSquareModel compareMitrix] transferLeft];
                } else if (model.direct == SquareDirect180) {
                    compare = [[[RightAngSquareModel compareMitrix] transferLeft] transferLeft];
                } else if (model.direct == SquareDirect270) {
                    compare = [[[[RightAngSquareModel compareMitrix] transferLeft] transferLeft] transferLeft];
                }
            } else if ([model isKindOfClass:[MSquareModel class]]) {
                if (model.direct == SquareDirectUp) {
                    compare = [MSquareModel compareMitrix];
                } else if (model.direct == SquareDirect90) {
                    compare = [[MSquareModel compareMitrix] transferLeft];
                } else if (model.direct == SquareDirect180) {
                    compare = [[[MSquareModel compareMitrix] transferLeft] transferLeft];
                } else if (model.direct == SquareDirect270) {
                    compare = [[[[MSquareModel compareMitrix] transferLeft] transferLeft] transferLeft];
                }
            } else if ([model isKindOfClass:[ObliqueLeftSquareModel class]]) {
                if (model.direct == SquareDirectUp) {
                    compare = [ObliqueLeftSquareModel compareMitrix];
                } else if (model.direct == SquareDirect90) {
                    compare = [[ObliqueLeftSquareModel compareMitrix] transferLeft];
                } else if (model.direct == SquareDirect180) {
                    compare = [[[ObliqueLeftSquareModel compareMitrix] transferLeft] transferLeft];
                } else if (model.direct == SquareDirect270) {
                    compare = [[[[ObliqueLeftSquareModel compareMitrix] transferLeft] transferLeft] transferLeft];
                }
            }
            
            if (compare != nil) {
                for (int r = 0; r < compare.row; r++) {
                    for (int c = 0; c < compare.col; c++) {
                        PixelModel *pModel = [compare valueAtRow:r col:c];
                        if (pModel.alpha > 0) {
                            HitModel *hModel = [self valueAtRow:model.positionY + r col:model.positionX + c];
                            if (hModel) {
                                [hModel.hitTypeArray addObject:[[NSNumber alloc] initWithInteger:model.type]];
                            }
                        }
                    }
                }
            }
        }
    }
}

@end
