//
//  IntMatrix.m
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "IntMatrix.h"

@implementation IntMatrix {
    NSInteger *_arr;
}

#pragma mark - Lifecycle

- (instancetype)initWithRow:(NSInteger)row col:(NSInteger)col {
    return [self initWithRow:row col:col value:-1];
}

- (instancetype)initWithRow:(NSInteger)row col:(NSInteger)col value:(NSInteger)initValue {
    if (self = [super init]) {
        _row = row;
        _col = col;
        
        _arr = malloc(sizeof(NSInteger) * row * col);
        
        for (NSInteger r = 0; r < _row; ++r) {
            for (NSInteger c = 0; c < _col; ++c) {
                NSInteger index = r * _col + c;
                _arr[index] = initValue;
            }
        }
    }
    return self;
}

- (void)dealloc {
    free(_arr);
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

- (void)setIntValue:(NSInteger)value row:(NSInteger)r col:(NSInteger)c {
    if ([self invalidRow:r] || [self invalidCol:c]) {
        return;
    }
    
    NSInteger index = r * _col + c;
    _arr[index] = value;
}

- (void)setIntValue:(NSInteger)value at:(CGPoint)position {
    [self setIntValue:value row:position.y col:position.x];
}

#pragma mark - Get

- (NSInteger)intValueAtRow:(NSInteger)r col:(NSInteger)c {
    if ([self invalidRow:r] || [self invalidCol:c]) {
        return -1;
    }
    
    NSInteger index = r * _col + c;
    return _arr[index];
}

- (NSInteger)intValueAt:(CGPoint)position {
    return [self intValueAtRow:position.y col:position.x];
}

#pragma mark - Debug

- (UIImage *)logImage {
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
            NSInteger value = [self intValueAtRow:r col:c];
            
            if (value == 0) {
                fillColor = [UIColor whiteColor];
            } else {
                fillColor = [UIColor blackColor];
            }
            CGContextSetFillColorWithColor(contextRef, fillColor.CGColor);
            CGContextFillRect(contextRef, CGRectMake(c, r, 1, 1));
        }
    }
    
    
    UIImage *imageOut = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOut;
}

- (void)printLogInfo {
    NSLog(@"------------------------------------------------------------------------");
    NSMutableString *resutString = [NSMutableString string];
    for (NSInteger r = 0; r < _row; ++r) {
        [resutString appendFormat:@"\n"];
        
        for (NSInteger c = 0; c < _col; ++c) {
            NSInteger value = [self intValueAtRow:r col:c];
            [resutString appendFormat:@"%@ ", @(value)];
        }
    }
    
    NSLog(@"%@", resutString);
    
    NSLog(@"------------------------------------------------------------------------");
}

@end
