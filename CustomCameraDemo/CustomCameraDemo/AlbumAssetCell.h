//
//  AlbumAssetCell.h
//  CustomCameraDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface AlbumAssetCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *sortLabel;

- (void)setDataSourceWith:(PHAsset *)asset;

@end

NS_ASSUME_NONNULL_END
