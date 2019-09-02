//
//  UIImage+Scale.h
//  MetalSystomFilterDemo
//
//  Created by Rock on 2019/9/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Scale)

- (UIImage *)scaleToFillSize:(CGSize)newSize;

@end

NS_ASSUME_NONNULL_END
