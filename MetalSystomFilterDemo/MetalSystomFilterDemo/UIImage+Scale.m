//
//  UIImage+Scale.m
//  MetalSystomFilterDemo
//
//  Created by Rock on 2019/9/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (Scale)

- (UIImage *)scaleToFillSize:(CGSize)newSize {
  if (newSize.width > self.size.width || newSize.height > self.size.height) {
    return self;
  }

  CGImageRef imgRef = self.CGImage;

  size_t destWidth = (size_t)(newSize.width * self.scale);
  size_t destHeight = (size_t)(newSize.height * self.scale);
  if (self.imageOrientation == UIImageOrientationLeft
      || self.imageOrientation == UIImageOrientationLeftMirrored
      || self.imageOrientation == UIImageOrientationRight
      || self.imageOrientation == UIImageOrientationRightMirrored) {
    size_t temp = destWidth;
    destWidth = destHeight;
    destHeight = temp;
  }

  size_t bitsPerComponent = CGImageGetBitsPerComponent(imgRef); // rgba 一般为8
  size_t bytesPerRow = CGImageGetBytesPerRow(imgRef); // 一行占多少bytes 4 * width
  /// Create an ARGB bitmap context

  CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
  CGContextRef bmContext = CGBitmapContextCreate(NULL,
                                                 destWidth,
                                                 destHeight,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 kCGImageAlphaPremultipliedFirst);

  if (!bmContext) {
    return nil;
  }

  /// Image quality
  CGContextSetShouldAntialias(bmContext, true);
  CGContextSetAllowsAntialiasing(bmContext, true);
  CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);

  /// Draw the image in the bitmap context

  UIGraphicsPushContext(bmContext);
  CGContextDrawImage(bmContext, CGRectMake(0.0f, 0.0f, destWidth, destHeight), self.CGImage);
  UIGraphicsPopContext();

  /// Create an image object from the context
  CGImageRef scaledImageRef = CGBitmapContextCreateImage(bmContext);
  UIImage* scaled = [UIImage imageWithCGImage:scaledImageRef scale:self.scale orientation:self.imageOrientation];

  /// Cleanup
  CGImageRelease(scaledImageRef);
  CGContextRelease(bmContext);

  return scaled;
}

@end
