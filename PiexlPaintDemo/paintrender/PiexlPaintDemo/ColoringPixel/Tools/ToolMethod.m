//
//  ToolMethod.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/25.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "ToolMethod.h"

#import "IntMatrix.h"

@implementation ToolMethod

+ (PixelModel *)piexlModelWithMatrix:(PixelMatrix *) matrix
                                 row:(NSUInteger) row
                              column:(NSUInteger) col {
    id value = [matrix valueAtRow:row col:col];
    if (value == [NSNull null]) {
        return nil;
    }
    return (PixelModel *)value;
}

/// 判断两个点的颜色是否相同
/// @param pointOne 点1
/// @param otherPoint 点2
+ (BOOL)colorIsEqualWithMatrix:(PixelMatrix *) matrix pointOne:(CGPoint)pointOne otherPoint:(CGPoint)otherPoint {
    PixelModel *firstItem = [ToolMethod piexlModelWithMatrix:matrix row:pointOne.y column:pointOne.x];
    PixelModel *secondItem = [ToolMethod piexlModelWithMatrix:matrix row:otherPoint.y column:otherPoint.x];
    if (!firstItem || !secondItem) {
        NSLog(@"数据为空，可能矩阵索引越界");
        return NO;
    }
    
    // TODO : 测试版本，不透明就认为颜色一致
    if (firstItem.alpha != 0 && secondItem.alpha != 0) {
        return YES;
    }
    return NO;
    
    return [firstItem isEqual:secondItem];
}

+ (UIColor *)colorWithHexString:(NSString *)hexString {
    if (hexString.length <= 0) {
        return nil;
    }
    
    if ([hexString hasPrefix:@"0X"]) {
        hexString = [hexString substringFromIndex:2];
    }
    if ([hexString hasPrefix:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }
    // 从六位数值中找到RGB对应的位数并转换
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //R、G、B
    NSString *rString = [hexString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [hexString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [hexString substringWithRange:range];
    
    NSString *alpaString = nil;
    if (hexString.length == 8) {
        range.location = 6;
        alpaString = [hexString substringWithRange:range];
    }
    
    unsigned int r, g, b, a;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    CGFloat alpha = 1.0;
    if (alpaString && ![alpaString isEqualToString:@""]) {
        [[NSScanner scannerWithString:alpaString] scanHexInt:&a];
        alpha = (a / 255.0);
    }
    
    return [UIColor colorWithRed:(r / 255.0) green:(g/ 255.0) blue:(b / 255.0) alpha:alpha];
}


@end
