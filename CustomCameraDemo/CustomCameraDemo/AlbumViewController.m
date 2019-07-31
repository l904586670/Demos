//
//  AlbumViewController.m
//  CustomCameraDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "AlbumViewController.h"

#import "UserAuthorization.h"
#import "AlbumAssetCell.h"
#import "YiquxPhotosUtility.h"

static NSString * const kCellId = @"albumVC-collecitonView-cell";

@interface AlbumViewController () <UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) PHFetchResult<PHAsset *> *results;

@property (nonatomic, strong) NSMutableArray <NSIndexPath *>*selectIndexPaths;
@property (nonatomic, strong) NSMutableArray <PHAsset *>*selectItems;

@end

@implementation AlbumViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _selectIndexPaths = [NSMutableArray array];
  _selectItems = [NSMutableArray array];
  __weak typeof(self) weakSelf = self;
  
  [UserAuthorization requestAlbumPermission:^{
    [weakSelf.collectionView reloadData];
  } deniedHandler:^(NSInteger authStatus) {
    NSLog(@"没有给权限");
  }];
  
//  _collectionView = [];
  [self setupUI];
  
  [self requesetDataSource];
}

- (void)setupUI {
  UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
  if (@available(iOS 11.0, *)) {
    safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
  } else {
    // Fallback on earlier versions
  }
  
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  
  CGFloat itemSpacing = 3;
  CGFloat countPerRow = 4;
  CGFloat itemSizeWH = (screenSize.width - countPerRow * itemSpacing) / countPerRow;
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.itemSize = CGSizeMake(itemSizeWH, itemSizeWH);
  layout.minimumLineSpacing = itemSpacing;
  layout.minimumInteritemSpacing = 0;
  layout.sectionInset = UIEdgeInsetsMake(0, 0, safeAreaInsets.bottom, 0);
  
  CGFloat posY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
  CGRect frame = CGRectMake(0, posY, screenSize.width, screenSize.height - posY);
  
  _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
  _collectionView.dataSource = self;
  _collectionView.delegate = self;
  _collectionView.backgroundColor = [UIColor whiteColor];
  _collectionView.showsVerticalScrollIndicator = NO;
  
  [_collectionView registerClass:[AlbumAssetCell class] forCellWithReuseIdentifier:kCellId];
  [self.view addSubview:_collectionView];
  
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeInfoLight];
  [btn addTarget:self action:@selector(onSort) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
  self.navigationItem.rightBarButtonItem = item;
}

- (void)requesetDataSource {
  _results = [YiquxPhotosUtility imageAssetResultWithMediaSubtype:PHAssetMediaSubtypeNone];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return _results.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  AlbumAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellId forIndexPath:indexPath];
  
  PHAsset *asset = _results[indexPath.row];
  [cell setDataSourceWith:asset];
  if ([_selectIndexPaths containsObject:indexPath]) {
    cell.sortLabel.text = [NSString stringWithFormat:@"%@", @([_selectIndexPaths indexOfObject:indexPath])];
  } else {
    cell.sortLabel.text = nil;
  }
  
  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  PHAsset *asset = _results[indexPath.row];
  AlbumAssetCell *cell = (AlbumAssetCell *)[collectionView cellForItemAtIndexPath:indexPath];
  if ([_selectItems containsObject:asset]) {
    [_selectItems removeObject:asset];
  } else {
    [_selectItems addObject:asset];
  }
  
  if ([_selectIndexPaths containsObject:indexPath]) {
    [_selectIndexPaths removeObject:indexPath];
  } else {
    [_selectIndexPaths addObject:indexPath];
  }
  cell.sortLabel.text = nil;
  [collectionView reloadItemsAtIndexPaths:_selectIndexPaths];
}

- (void)onSort {
  [YiquxPhotosUtility asynchRequestImagesWith:_selectItems completionHandler:^(NSArray * _Nonnull sortImages) {
    
  }];
  
}

@end
