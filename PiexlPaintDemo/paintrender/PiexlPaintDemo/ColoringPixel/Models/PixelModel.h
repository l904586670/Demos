//
//  PexelModel.h
//  PiexlPaintDemo
//
//  Created by Rock on 2020/5/20.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelModel : NSObject

@property (nonatomic, assign) NSUInteger red;
@property (nonatomic, assign) NSUInteger green;
@property (nonatomic, assign) NSUInteger blue;
@property (nonatomic, assign) NSUInteger alpha;
@property (nonatomic, assign) BOOL isCompareIgnore;

+ (PixelModel *)alphaTrueModel;

- (Boolean)compareWithModel:(PixelModel *)model;

- (void)setClearColor;


/// 存储矩阵中有多少个纯色 key
- (NSString *)piexlModelToHexRGBA;

+ (PixelModel *)piexlModelFromHexString:(NSString *)hexString;

@end

NS_ASSUME_NONNULL_END
