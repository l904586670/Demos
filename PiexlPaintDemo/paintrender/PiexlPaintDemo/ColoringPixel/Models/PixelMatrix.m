//
//  PixelMatrix.m
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "PixelMatrix.h"

#import "PixelModel.h"

@interface PixelMatrix ()

@property (nonatomic, strong) NSMutableArray *valueArray;

@end

@implementation PixelMatrix

- (instancetype)init {
    if (self = [super init]) {
        _row = 0;
        _col = 0;
    }
    return self;
}

- (instancetype)initWithRow:(NSInteger)row
                        col:(NSInteger)col {
    if (self = [super init]) {
        _row = row;
        _col = col;
        
        _valueArray = [[NSMutableArray alloc] initWithCapacity:row];
        for (NSInteger r = 0; r < self.row; ++r) {
            [_valueArray addObject:[[NSMutableArray alloc] initWithCapacity:col]];
            for (NSInteger c = 0; c < self.col; ++c) {
                PixelModel *model = [[PixelModel alloc] init];
                [_valueArray[r] addObject:model];
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

- (void)setValue:(PixelModel *)value row:(NSInteger)r col:(NSInteger)c {
    if ([self invalidRow:r] || [self invalidCol:c]) {
        return;
    }
    
    _valueArray[r][c] = value;
}

- (void)setCompareIgnore:(BOOL )isIgnore row:(NSInteger)r col:(NSInteger)c {
    if ([self invalidRow:r] || [self invalidCol:c]) {
        return;
    }
    PixelModel *model = _valueArray[r][c];
    model.isCompareIgnore = isIgnore;
}

- (void)setValue:(PixelModel *)value at:(CGPoint)position {
    [self setValue:value row:position.y col:position.x];
}

#pragma mark - Get

- (PixelModel *)valueAtRow:(NSInteger)r col:(NSInteger)c {
    if ([self invalidRow:r] || [self invalidCol:c]) {
        return [[PixelModel alloc] init];
    }
    
    return _valueArray[r][c];
}

- (PixelModel *)valueAt:(CGPoint)position {
    return [self valueAtRow:position.y col:position.x];
}

#pragma mark - Debug

- (UIImage *)pixelPreviewImage {
    CGFloat scale = 1.0;
    CGSize size = CGSizeMake(_col * scale, _row * scale);
    UIGraphicsBeginImageContextWithOptions(size, NO, 1);
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    if (!contextRef) {
        return nil;
    }
    
    UIColor *fillColor = nil;
    /*画矩形*/
    for (NSInteger r = 0; r < _row; ++r) {
        for (NSInteger c = 0; c < _col; ++c) {
            id value = [self valueAtRow:r col:c];
            if (value == [NSNull null]) {
                fillColor = [UIColor clearColor];
            } else {
                PixelModel *pixelModel = (PixelModel *)value;
                if (pixelModel.alpha == 0) {
                    fillColor = [UIColor clearColor];
                } else {
                    fillColor = [UIColor colorWithRed:pixelModel.red/255.0 green:pixelModel.green/255.0 blue:pixelModel.blue/255.0 alpha:pixelModel.alpha/255.0];
                }
            }
            CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
            CGContextFillRect(contextRef, CGRectMake(c, r, 1, 1));
        }
    }
    
    UIImage *imageOut = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOut;
}

- (Boolean)compareWithMatrix:(PixelMatrix *)matrix {
    if (self.row == matrix.row && self.col == matrix.col) {
        for (int i = 0; i < matrix.row; i++) {
            for (int j = 0; j < matrix.col; j++) {
                PixelModel *modelA = [matrix valueAtRow:i col:j];
                PixelModel *modelB = [self valueAtRow:i col:j];
                if (![modelB compareWithModel:modelA]) {
                    return false;
                }
            }
        }
        return true;
    }
    return false;
}

- (PixelMatrix *)subMatrixWithRow:(NSInteger)row col:(NSInteger)col offsetRow:(NSInteger)offsetRow offsetCol:(NSInteger)offsetCol {
    if (self.row > row + offsetRow && self.col > col + offsetCol) {
        PixelMatrix *subMatrix = [[PixelMatrix alloc] initWithRow:offsetRow col:offsetCol];
        for (int i = 0; i < offsetRow; i++) {
            for (int j = 0; j < offsetCol; j++) {
                PixelModel *model = [self valueAtRow:row + i col:col + j];
                [subMatrix setValue:model row:i col:j];
            }
        }
        return subMatrix;
    }
    return nil;
}

- (PixelMatrix *)filterMatrixByColor:(UIColor *)color {
    CGFloat r = 0.0;
    CGFloat g = 0.0;
    CGFloat b = 0.0;
    CGFloat a = 0.0;
    BOOL result = [color getRed:&r green:&g blue:&b alpha:&a];
    if (result) {
        NSInteger red = floor(r * 255);
        NSInteger green = floor(g * 255);
        NSInteger blue = floor(b * 255);
        NSInteger alpha = floor(a * 255);
        
        PixelMatrix *pixelMatrix = [[PixelMatrix alloc] initWithRow:self.row col:self.col];
        for (NSInteger r = 0; r < self.row; ++r) {
            for (NSInteger c = 0; c < self.col; ++c) {
                PixelModel *pixelModel = [self valueAtRow:r col:c];
                if (pixelModel.red == red && pixelModel.blue == blue && pixelModel.alpha == alpha && pixelModel.green == green) {
                    [pixelMatrix setValue:pixelModel row:r col:c];
                }
            }
        }
        
        return pixelMatrix;
    } else {
        return nil;
    }
}

#pragma mark - Debug Methods

- (void)printLogInfo {
    NSInteger currentValue = 0;
    NSLog(@"------------------------------------------------------------------------");
    NSMutableString *resutString = [NSMutableString string];
    for (NSInteger r = 0; r < _row; ++r) {
        [resutString appendFormat:@"\n"];
        for (NSInteger c = 0; c < _col; ++c) {
            id value = [self valueAtRow:r col:c];
            
            if (value == [NSNull null]) {
                currentValue = 0;
            } else {
                PixelModel *pixelModel = (PixelModel *)value;
                if (pixelModel.alpha == 0) {
                    currentValue = 0;
                } else {
                    currentValue = 1;
                }
            }
            [resutString appendFormat:@"%@ ", @(currentValue)];
        }
    }
    
    NSLog(@"%@", resutString);
    NSLog(@"------------------------------------------------------------------------");
}

@end
