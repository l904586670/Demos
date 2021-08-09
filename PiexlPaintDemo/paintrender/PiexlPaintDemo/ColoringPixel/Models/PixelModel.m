//
//  PexelModel.m
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "PixelModel.h"

@implementation PixelModel
- (instancetype)init {
    if (self = [super init]) {
        self.red = 0;
        self.green = 0;
        self.blue = 0;
        self.alpha = 0;
        self.isCompareIgnore = false;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[PixelModel class]]) {
        return NO;
    }
    
    PixelModel *obj = (PixelModel *)object;
    return self.red == obj.red && self.green == obj.green && self.blue == obj.blue && self.alpha == obj.alpha;
}

+ (PixelModel *)alphaTrueModel {
    PixelModel *alphaTrueModel = [[PixelModel alloc] init];
    alphaTrueModel.alpha = 255;
    return alphaTrueModel;
}

- (Boolean)compareWithModel:(PixelModel *)model {
    if (model != nil) {
        if (model.isCompareIgnore) {
            return true;
        }
        if (self.isCompareIgnore) {
            return true;
        }
        if (model.alpha == self.alpha)
        {
            return true;
        }
    }
    return false;
}

- (void)setClearColor {
    self.red = 0;
    self.green = 0;
    self.blue = 0;
    self.alpha = 0;
}

- (NSString *)piexlModelToHexRGBA {
    static NSString *stringFormat = @"%02x%02x%02x%02x";
    return [NSString stringWithFormat:stringFormat,
            (NSUInteger)(self.red),
            (NSUInteger)(self.green),
            (NSUInteger)(self.blue),
            (NSUInteger)(self.alpha)];
}

+ (PixelModel *)piexlModelFromHexString:(NSString *)hexString {
    return nil;
}

@end
