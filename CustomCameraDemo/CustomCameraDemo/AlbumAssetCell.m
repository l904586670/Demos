//
//  AlbumAssetCell.m
//  CustomCameraDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "AlbumAssetCell.h"

#import "YiquxPhotosUtility.h"

@interface AlbumAssetCell ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation AlbumAssetCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self imageView];
    
    [self sortLabel];
  }
  return self;
}

- (UIImageView *)imageView {
  if (!_imageView) {
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:_imageView];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [_imageView setClipsToBounds:YES];
  }
  return _imageView;
}

- (UILabel *)sortLabel {
  if (!_sortLabel) {
    _sortLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _sortLabel.textColor = [UIColor redColor];
    _sortLabel.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:_sortLabel];
  }
  return _sortLabel;
}

- (void)prepareForReuse {
  _sortLabel.text = nil;
}

- (void)setDataSourceWith:(PHAsset *)asset {
  CGFloat scale = [UIScreen mainScreen].scale;
  CGSize itemSize = CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
  self.tag = [YiquxPhotosUtility asynchRequestAssetThumbnailWithAsset:asset targetSize:itemSize completionHandler:^(UIImage * _Nonnull result, NSDictionary * _Nonnull info) {
    if ([info[PHImageResultRequestIDKey] integerValue] == self.tag) {
      self.imageView.image = result;
    }
    
  }];
}

@end
