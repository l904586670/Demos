//
//  MetalFilterCell.m
//  MetalSystomFilterDemo
//
//  Created by Rock on 2019/9/2.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "MetalFilterCell.h"

@implementation MetalFilterCell

- (UIImageView *)imageView {
  if (!_imageView) {
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:_imageView];
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
  }
  return _imageView;
}

@end
