//
//  ViewController.m
//  MetalSystomFilterDemo
//
//  Created by User on 2019/8/6.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "BaseMetalShaderFilter.h"
#import "MetalFilterCell.h"
#import "UIImage+Scale.h"

@interface ViewController () <UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UIImage *originImage;

@property (nonatomic, strong) UICollectionView *lutCollectionView;

@property (nonatomic, strong) UIImage *scaleImage;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.title = @"基本滤镜";
  
  _originImage = [UIImage imageNamed:@"img1.jpg"];

  CGRect frame = [self innerRectWithAspectRatio:_originImage.size outRect:self.view.bounds];
  frame.origin.y = CGRectGetMinY(frame) / 2.0;
  _imgView = [[UIImageView alloc] initWithFrame:frame];
  [self.view addSubview:_imgView];
  _imgView.image = _originImage;
  
  NSArray *titles = @[@"饱和度", @"对比度", @"亮度", @"色温", @"透明度"];
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  CGRect firstItemRect = CGRectMake(60, CGRectGetMaxY(frame) + 10, screenSize.width - 70, 40);
  CGFloat maxPosY = 0.0;
  for (NSInteger i = 0; i < titles.count; i++) {
    UISlider *slider = [self sliderWithFrame:CGRectOffset(firstItemRect, 0, i * 40) title:titles[i]];
    slider.tag = i;
    if (i == (titles.count - 1)) {
      slider.value = 1.0;
      maxPosY = CGRectGetMaxY(slider.frame);
    }
  }
  
  [self lutBtnUIWithPosY:maxPosY + 10.0];
}

- (CGRect)innerRectWithAspectRatio:(CGSize)aspectRatio outRect:(CGRect)outRect {
  CGFloat factor = aspectRatio.width / aspectRatio.height;
  CGFloat outRectFactor = outRect.size.width / outRect.size.height;
  CGFloat width = 0.0;
  CGFloat height = 0.0;
  CGFloat posX = 0.0;
  CGFloat posY = 0.0;
  if (factor > outRectFactor) {
    // 最大值为宽
    width = CGRectGetWidth(outRect);
    height = width / factor;
    posX = 0.0;
    posY = (CGRectGetHeight(outRect) - height)/2.0;
  } else {
    // 最大值为高
    height = CGRectGetHeight(outRect);
    width = factor * height;
    posY = 0.0;
    posX = (CGRectGetWidth(outRect) - width)/2.0;
  }
  return CGRectMake(posX, posY, width, height);
}

#pragma mark - UI

- (UISlider *)sliderWithFrame:(CGRect)frame title:(NSString *)title {
  UISlider *slider = [[UISlider alloc] initWithFrame:frame];
  [self.view addSubview:slider];
  [slider addTarget:self
             action:@selector(onSliderValueChangeEnd:)
   forControlEvents:UIControlEventTouchUpInside];
  slider.value = 0.5;
  
  CGRect titleFrame = CGRectMake(CGRectGetMinX(frame) - 50, CGRectGetMinY(frame), 40, CGRectGetHeight(frame));
  UILabel *label = [[UILabel alloc] initWithFrame:titleFrame];
  [self.view addSubview:label];
  label.textColor = [UIColor blackColor];
  label.font = [UIFont systemFontOfSize:11.0];
  label.text = title;
//  [label sizeToFit];
  return slider;
}

- (void)lutBtnUIWithPosY:(CGFloat)posY {
  CGSize screenSize = [UIScreen mainScreen].bounds.size;

  CGFloat itemWH = 70;
  _scaleImage = [_originImage scaleToFillSize:CGSizeMake(itemWH * [UIScreen mainScreen].scale, itemWH * [UIScreen mainScreen].scale)];

  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  layout.itemSize = CGSizeMake(itemWH, itemWH);
  layout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
  layout.minimumLineSpacing = 10;

  CGRect frame = CGRectMake(0, posY, screenSize.width, itemWH);

  _lutCollectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
  _lutCollectionView.dataSource = self;
  _lutCollectionView.delegate = self;
  _lutCollectionView.backgroundColor = [UIColor clearColor];
  [self.view addSubview:_lutCollectionView];

  [_lutCollectionView registerClass:[MetalFilterCell class] forCellWithReuseIdentifier:@"cellId"];
}

#pragma mark - Action

- (void)onSliderValueChangeEnd:(UISlider *)sender {
  NSInteger index = sender.tag;
  CGFloat minValue = 0.0;
  CGFloat maxValue = 1.0;
  CGFloat value = sender.value * (maxValue - minValue) + minValue;
  if (0 == index) {
    maxValue = 2.0;
    value = sender.value * (maxValue - minValue) + minValue;
    [BaseMetalShaderFilter shareInstance].saturation = value;
  } else if (1 == index) {
    minValue = 0.5;
    maxValue = 1.5;
    value = sender.value * (maxValue - minValue) + minValue;
    [BaseMetalShaderFilter shareInstance].contrast = value;
  } else if (2 == index) {
    minValue = 0.5;
    maxValue = 1.5;
    value = sender.value * (maxValue - minValue) + minValue;
    [BaseMetalShaderFilter shareInstance].brightness = value;
  } else if (3 == index) {
    minValue = -1.0;
    maxValue = 1.0;
    value = sender.value * (maxValue - minValue) + minValue;
    [BaseMetalShaderFilter shareInstance].temperature = value;
  } else if (4 == index) {
    [BaseMetalShaderFilter shareInstance].alpha = value;
  }
  
  UIImage *resultImage = [[BaseMetalShaderFilter shareInstance] filterWithOriginImage:_originImage];
  _imgView.image = resultImage;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return 14;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  MetalFilterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellId" forIndexPath:indexPath];

  UIImage *lutImage = [UIImage imageNamed:[NSString stringWithFormat:@"lut-%@.png", @(indexPath.row)]];
  UIImage *resultImage = [[BaseMetalShaderFilter shareInstance] lutFilterWithOriginImage:_scaleImage lutImage:lutImage];

  cell.imageView.image = resultImage;

  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

  UIImage *lutImage = [UIImage imageNamed:[NSString stringWithFormat:@"lut-%@.png", @(indexPath.row)]];

  UIImage *resultImage = [[BaseMetalShaderFilter shareInstance] lutFilterWithOriginImage:_originImage lutImage:lutImage];
  _imgView.image = resultImage;
}




@end
