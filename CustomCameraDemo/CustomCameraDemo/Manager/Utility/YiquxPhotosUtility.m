//
//  YiquxPhotosUtility.m
//
//  Created by Rock on 2019/1/15.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import "YiquxPhotosUtility.h"

@implementation YiquxPhotosUtility

#pragma mark - Delete Album Data

+ (void)deletePhAsset:(PHAsset *)phAsset
        resultHandler:(void(^)(BOOL success, NSError *error))handler {

  if (!phAsset) {
    NSAssert(NO, @"delete asset Error : asset can not be nil");
    if (handler) {
      handler(NO, [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"要删除的资源为nil"}]);
    }
    return;
  }
  
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    [PHAssetChangeRequest deleteAssets:@[phAsset]];
  } completionHandler:^(BOOL success, NSError * _Nullable error) {
    if (handler) {
      handler(success, error);
    }
  }];
}

#pragma mark - Write To Sandbox

+ (void)writeLivePhotoToSandboxWithAsset:(PHAsset *)asset
                          videoOutputUrl:(NSURL * _Nullable)videoUrl
                            imgOutputUrl:(NSURL * _Nullable)imgUrl
                           resultHandler:(void(^)(BOOL success, NSURL *videoOutputUrl, NSURL *imgOutputUrl, NSError *error))handler {
  NSParameterAssert(asset);
  if (asset.mediaSubtypes != PHAssetMediaSubtypePhotoLive) {
    NSAssert(NO, @"write livePhoto asset not be LivePhoto meida");
    if (handler) {
      NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"资源不是livePhoto类型的"}];
      handler(NO, nil, nil, error);
    }
    return;
  }
  
  PHAssetResourceRequestOptions *opt = [[PHAssetResourceRequestOptions alloc] init];
  opt.networkAccessAllowed = YES;
  
  //
  if (!videoUrl) {
    NSString *movName = [NSString stringWithFormat:@"%@.mov", @([[NSDate date] timeIntervalSince1970])];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:movName];
    videoUrl = [NSURL fileURLWithPath:tempPath];
  }
  if (!imgUrl) {
    NSString *imgName = [NSString stringWithFormat:@"%@.jpg", @([[NSDate date] timeIntervalSince1970])];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:imgName];
    imgUrl = [NSURL fileURLWithPath:tempPath];
  }
  
  [[NSFileManager defaultManager] removeItemAtURL:videoUrl error:nil];
  [[NSFileManager defaultManager] removeItemAtURL:imgUrl error:nil];
  
  NSArray *resources = [PHAssetResource assetResourcesForAsset:asset];
  // first -> img  last -> mov
  __block NSError *writeError = nil;
  
  dispatch_group_t group = dispatch_group_create();
  
  dispatch_group_enter(group);
  [[PHAssetResourceManager defaultManager] writeDataForAssetResource:[resources firstObject] toFile:imgUrl options:opt completionHandler:^(NSError * _Nullable error) {
    writeError = error;
    dispatch_group_leave(group);
  }];
  
  dispatch_group_enter(group);
  [[PHAssetResourceManager defaultManager] writeDataForAssetResource:[resources lastObject] toFile:imgUrl options:opt completionHandler:^(NSError * _Nullable error) {
    writeError = error;
    dispatch_group_leave(group);
  }];
  
  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    if (handler) {
      handler(!writeError, videoUrl, imgUrl, writeError);
    }
  });
}

#pragma mark - Request Album Data

+ (void)asynchRequestImagesWith:(PHFetchResult<PHAsset *> *)results
             completionHandler:(void(^)(NSArray *sortImages))hander {
  NSMutableArray <UIImage *>*images = [NSMutableArray array];
  for (PHAsset *asset in results) {
    UIImage *originalImage = [[self class] synchRequestOriginImageWithAsset:asset];
    if (originalImage) {
      [images addObject:originalImage];
    }
  }

  if (hander) {
    hander(images);
  }
}

+ (NSArray <UIImage *>*)imagesWithImageAssets:(NSArray <PHAsset *>*)results {
  NSMutableArray <UIImage *>*images = [NSMutableArray array];
  for (PHAsset *asset in results) {
    UIImage *originalImage = [[self class] synchRequestOriginImageWithAsset:asset];
    if (originalImage) {
      [images addObject:originalImage];
    }
  }
  return [images mutableCopy];
}

+ (PHFetchResult<PHAsset *> *)requestBurstResultWithAsset:(PHAsset *)asset {
  if (!asset.representsBurst) {
    NSAssert(NO, @"Error : 当前图片资源不是连拍类型");
    return nil;
  }

  PHFetchOptions *opt = [[PHFetchOptions alloc] init];
  opt.includeAllBurstAssets = YES;
  return [PHAsset fetchAssetsWithBurstIdentifier:asset.burstIdentifier options:opt];
}


+ (PHImageRequestID)requestLivePhotoWithAsset:(PHAsset *)asset resultHandler:(void(^)(PHLivePhoto *livePhoto, NSDictionary * info))handler API_AVAILABLE(ios(9.1)) {
  if (asset.mediaSubtypes != PHAssetMediaSubtypePhotoLive) {
    NSAssert(NO, @"Error : requet LivePhoto Not LivePhoto mediaType");
    if (handler) {
      handler(nil, nil);
    }
    return 0;
  }

  PHLivePhotoRequestOptions *opt = [[PHLivePhotoRequestOptions alloc] init];
  opt.networkAccessAllowed = YES;

  return [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:opt resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
    // 屏蔽缩略图
    if (!info[PHImageResultIsDegradedKey]) {
      if (handler) {
        handler(livePhoto, info);
      }
    }
  }];
}


+ (void)requestLivePhotoResourceVideoWith:(PHAsset *)asset resultHandler:(void (^)(AVAsset * asset, NSURL *fileUrl))handler API_AVAILABLE(ios(9.1)) {
  if (!asset) {
    handler(nil, nil);
    return;
  }
  if (asset.mediaSubtypes != PHAssetMediaSubtypePhotoLive) {
    NSAssert(NO, @"asset.mediaSubtypes != PHAssetMediaSubtypePhotoLive");
    handler(nil, nil);
    return;
  }

  NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"livePhotoTempVideo.mov"];
  NSURL *fileUrl = [NSURL fileURLWithPath:tempPath];
  BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:tempPath];
  if (isExists) {
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
  }

  NSArray <PHAssetResource *>*uiResources = [PHAssetResource assetResourcesForAsset:asset];
  for (PHAssetResource *assetResource in uiResources) {
    if (assetResource.type != PHAssetResourceTypePhoto) {
      PHAssetResourceRequestOptions *opt = [[PHAssetResourceRequestOptions alloc] init];
      opt.networkAccessAllowed = YES;

      [[PHAssetResourceManager defaultManager] writeDataForAssetResource:assetResource toFile:fileUrl options:opt completionHandler:^(NSError * _Nullable error) {
        if (!error) {
          AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:fileUrl options:@{AVURLAssetPreferPreciseDurationAndTimingKey : @YES}];
          if (handler) {
            handler(avAsset, fileUrl);
          }
        } else {
          NSAssert(NO, @"write livePhoto video to sandbox Error : %@", error);
          if (handler) {
            handler(nil, nil);
          }
        }
      }];
    }
  }
}

+ (PHImageRequestID)requestVideoAssetWithAsset:(PHAsset *)asset
                            resultHandler:(void (^)(AVAsset * asset, AVAudioMix *audioMix, NSDictionary * info))handler {
  if (asset.mediaType != PHAssetMediaTypeVideo) {
    NSAssert(NO, @"Error : requet Video Not video mediaType");
    if (handler) {
      handler(nil, nil, nil);
    }
    return 0;
  }

  PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
  options.version = PHImageRequestOptionsVersionCurrent;
  options.networkAccessAllowed = YES;
//  options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;

  return [[PHImageManager defaultManager] requestAVAssetForVideo:asset
                                                         options:options
                                                   resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                                     if (handler) {
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                         handler(asset, audioMix, info);
                                                       });
                                                     }
                                                   }];

}

+ (UIImage *)OriginImageWithAsset:(PHAsset *)asset {synchRequest
  PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
  options.synchronous = YES;
  options.networkAccessAllowed = YES;
  options.resizeMode = PHImageRequestOptionsResizeModeNone;

  __block UIImage *resultImage = nil;
  [[PHImageManager defaultManager] requestImageForAsset:asset
                                             targetSize:PHImageManagerMaximumSize
                                            contentMode:PHImageContentModeDefault
                                                options:options
                                          resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {

                                            resultImage = result;
                                          }];
  return resultImage;
}

+ (NSInteger)asynchRequestAssetOriginalImageWithAsset:(PHAsset *)asset
                                      completionHandler:(void(^)(UIImage *originalImage, NSDictionary * info))handler  {
  PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
  options.synchronous = NO;
  options.networkAccessAllowed = YES;
  options.resizeMode = PHImageRequestOptionsResizeModeNone;

  return [[PHImageManager defaultManager] requestImageForAsset:asset
                                                    targetSize:PHImageManagerMaximumSize
                                                   contentMode:PHImageContentModeDefault
                                                       options:options
                                                 resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                   // 排除取消, 错误, 站位图情况
                                                   BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                                                   if (downloadFinined && handler) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                       handler(result, info);
                                                     });
                                                   }
                                                 }];
}

+ (NSInteger)asynchRequestAssetThumbnailWithAsset:(PHAsset *)asset
                                       targetSize:(CGSize)targetSize
                                  completionHandler:(void (^)(UIImage *result, NSDictionary *info))handler {
  PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
  imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
  imageRequestOptions.networkAccessAllowed = YES;
  imageRequestOptions.synchronous = NO;

  if (CGSizeEqualToSize(targetSize, CGSizeZero)) {
    CGSize scrennSize = [UIScreen mainScreen].bounds.size;
    CGFloat itemWH = scrennSize.width / 4.0 * [UIScreen mainScreen].scale; // 手机相册一排显示4个
    targetSize = CGSizeMake(itemWH, itemWH);
  }

  return [[PHImageManager defaultManager] requestImageForAsset:asset
                                                    targetSize:targetSize
                                                   contentMode:PHImageContentModeAspectFill
                                                       options:imageRequestOptions
                                                 resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                    if (handler) {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                        handler(result, info);
                                                      });
                                                    }
                                                 }];
}

+ (PHFetchResult<PHAsset *> *)filterVideoAsset {
  PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
  // 按资源的创建时间排序
  fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
  fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d && !((mediaSubtype & %d) == %d) && !((mediaSubtype & %d) == %d)", PHAssetMediaTypeVideo, PHAssetMediaSubtypeVideoTimelapse, PHAssetMediaSubtypeVideoTimelapse, PHAssetMediaSubtypeVideoHighFrameRate,PHAssetMediaSubtypeVideoHighFrameRate];

  PHFetchResult<PHAsset *> *results = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:fetchOptions];

  return results;
}

+ (PHFetchResult<PHAsset *> *)imageAssetResultWithMediaSubtype:(PHAssetMediaSubtype)mediaSubtype {
  PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
  // 按资源的创建时间排序
  fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
  if (mediaSubtype > PHAssetMediaSubtypeNone && mediaSubtype < PHAssetMediaSubtypeVideoStreamed) {
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d && mediaSubtype == %d", PHAssetMediaTypeImage, mediaSubtype];
  } else {
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
  }

  return [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
}

+ (PHFetchResult<PHAsset *> *)filterAssetsWithAssetCollection:(PHAssetCollection *)assetCollection mediaType:(PHAssetMediaType)mediaType {
  PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
  fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];

  if (mediaType == PHAssetMediaTypeImage) {
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
  } else if (mediaType == PHAssetMediaTypeVideo) {
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d && !((mediaSubtype & %d) == %d) && !((mediaSubtype & %d) == %d)", PHAssetMediaTypeVideo, PHAssetMediaSubtypeVideoTimelapse, PHAssetMediaSubtypeVideoTimelapse, PHAssetMediaSubtypeVideoHighFrameRate,PHAssetMediaSubtypeVideoHighFrameRate];
  } else if (mediaType == PHAssetMediaTypeAudio) {

  }

  return [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
}

+ (UIImage *)synchRequestCollectionThumbnailWith:(PHAssetCollection *)assetCollection
                                      targetSize:(CGSize)targetSize {
  return [[self class] synchRequestCollectionThumbnailWith:assetCollection targetSize:targetSize mediaType:PHAssetMediaTypeUnknown];
}

+ (UIImage *)synchRequestCollectionThumbnailWith:(PHAssetCollection *)assetCollection targetSize:(CGSize)targetSize mediaType:(PHAssetMediaType)mediaType {
  // 按资源的创建时间排序
  PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
  fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
  fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", mediaType];

  // 获得某个相簿中的所有PHAsset对象
  PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
  PHAsset *asset = [assets firstObject];
  if (!asset) {
    return nil;
  }

  __block UIImage *thumbImage = nil;
  PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
  options.synchronous = YES;
  options.networkAccessAllowed = YES;
  options.resizeMode = PHImageRequestOptionsResizeModeFast;

  BOOL sizeResult = CGSizeEqualToSize(targetSize, CGSizeZero);
  if (sizeResult) {
    CGSize scrennSize = [UIScreen mainScreen].bounds.size;
    CGFloat itemWH = scrennSize.width / 3.0 * [UIScreen mainScreen].scale;
    targetSize = CGSizeMake(itemWH, itemWH);
  }

  [[PHImageManager defaultManager] requestImageForAsset:asset
                                             targetSize:targetSize
                                            contentMode:PHImageContentModeDefault
                                                options:options
                                          resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                            thumbImage = result;
                                          }];

  return thumbImage;
}


+ (NSArray <PHCollection *>*)getNormalCollectionWithMediaType:(PHAssetMediaType)mediaType {
  return [[self class] getUserCollectionWithMediaType:mediaType subType:PHAssetCollectionSubtypeAny];
}

+ (NSArray <PHCollection *>*)getUserCollectionWithMediaType:(PHAssetMediaType)mediaType
                                                    subType:(PHAssetCollectionSubtype)subType {
  // 列出所有相册智能相册
  PHFetchOptions *opt = [[PHFetchOptions alloc] init];
  opt.includeHiddenAssets = NO;

  PHFetchResult <PHAssetCollection *> *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:subType options:opt];
  // 列出所有用户创建的相册
  PHFetchResult <PHCollection *> *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];

  PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
  if (mediaType != PHAssetMediaTypeUnknown) {
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", mediaType];
  }

  NSMutableArray <PHCollection *>*allAlbumsMtArray = [NSMutableArray array];
  for (NSInteger i = 0; i < smartAlbums.count; i ++) {
    // 倒序排列,
    PHAssetCollection *collection = smartAlbums[smartAlbums.count - 1 - i];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions];
    if (fetchResult.count == 0) {
      // 如果相册里面没有信息,剔除
      continue;
    }

    if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
      [allAlbumsMtArray insertObject:collection atIndex:0];
    } else if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) {
      // 过滤隐藏相册
      continue;
    } else {
      [allAlbumsMtArray addObject:collection];
    }
  }

  for (NSInteger i = 0; i < topLevelUserCollections.count; i ++) {
    PHCollection *collection = topLevelUserCollections[i];
    if ([collection isKindOfClass:[PHAssetCollection class]]) {
      PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
      PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
      if (fetchResult.count == 0) {
        continue;
      }

      [allAlbumsMtArray addObject:collection];
    }
  }
  return allAlbumsMtArray;
}

+ (NSString *)timeFormattedWithVideoAsset:(PHAsset *)asset {
  if (asset.mediaType != PHAssetMediaTypeVideo) {
    NSAssert(NO, @"timeFormattedWithVideoAsset asset not be video mediaType");
    return nil;
  }

  NSTimeInterval timeInterval = asset.duration;
  NSInteger totalS = roundf(timeInterval);
  NSInteger seconds = totalS % 60;
  NSInteger minutes = (totalS / 60) % 60;
  NSInteger hours = totalS / 3600;

  if (hours == 0) {
    return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
  }

  return [NSString stringWithFormat:@"%ld:%02ld:%02ld",(long)hours, (long)minutes, (long)seconds];
}

#pragma mark - Creat Custom Album

+ (NSString *)appDisplayName {
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}

/**
 获取指定相册名称的相册
 */
+ (PHAssetCollection *)getAssetCollectionWithName:(NSString *)albumName {
  if (!albumName) {
    albumName = [[self class] appDisplayName];
  }
  // 获取所有自建相册
  PHFetchResult <PHAssetCollection *>*albumResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];

  for (PHAssetCollection *assetCollection in albumResult) {
    if ([assetCollection.localizedTitle isEqualToString:albumName]) {
      return assetCollection;
    }
  }
  return nil;
}


/**
 创建指定名称的相册

 @param albumName 相册名
 @param hander 完成后回调
 */
+ (void)creatAssetCollectionWithName:(NSString *)albumName
                   completionHandler:(void(^)(BOOL success, NSError *error))hander {
  if (!albumName) {
    albumName = [[self class] appDisplayName];
  }

  if ([[self class] getAssetCollectionWithName:albumName]) {
    if (hander) {
      hander(YES, nil);
    }
  } else {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
      [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
      NSLog(@"thread : %@", [NSThread currentThread]);
      if (hander) {
        hander(success, error);
      }
    }];
  }
}


+ (void)saveImageToAlbumWithFileUrl:(NSURL *)fileUrl albumName:(NSString *_Nullable)albumName completionHandler:(void(^)(BOOL success, NSError *error))hander {
  if (albumName) {
    // 需要保存到制定相册
    PHAssetCollection *assetCollection = [[self class] getAssetCollectionWithName:albumName];
    if (!assetCollection) {
      // 创建相册
      [[self class] creatAssetCollectionWithName:albumName completionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
          [[self class] saveDirectWith:fileUrl isVideo:NO albumName:albumName completionHandler:hander];
        } else {
          if (hander) {
            hander(NO, error);
          }
        }
      }];
    } else {
      [[self class] saveDirectWith:fileUrl isVideo:NO albumName:albumName completionHandler:hander];
    }
  } else {
    [[self class] saveDirectWith:fileUrl isVideo:NO albumName:albumName completionHandler:hander];
  }
}

+ (void)saveVideoToAlbumWithFileUrl:(NSURL *)fileUrl albumName:(NSString *_Nullable)albumName completionHandler:(void(^)(BOOL success, NSError *error))hander {
  if (albumName) {
    // 需要保存到制定相册
    PHAssetCollection *assetCollection = [[self class] getAssetCollectionWithName:albumName];
    if (!assetCollection) {
      // 创建相册
      [[self class] creatAssetCollectionWithName:albumName completionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
          [[self class] saveDirectWith:fileUrl isVideo:NO albumName:albumName completionHandler:hander];
        } else {
          if (hander) {
            hander(NO, error);
          }
        }
      }];
    } else {
      [[self class] saveDirectWith:fileUrl isVideo:YES albumName:albumName completionHandler:hander];
    }
  } else {
    [[self class] saveDirectWith:fileUrl isVideo:YES albumName:albumName completionHandler:hander];
  }
}

+ (void)saveAudioToAlbumWithFileUrl:(NSURL *)fileUrl completionHandler:(void(^)(BOOL success, NSError *error))handler {
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
    [request addResourceWithType:PHAssetResourceTypeAudio fileURL:fileUrl options:options];

  } completionHandler:^(BOOL success, NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (handler) {
        handler(success, error);
      }
    });
  }];
}

+ (void)saveGifToAlbumWithFileUrl:(NSURL *)gifFileUrl completionHandler:(void (^)(BOOL success, NSError * _Nullable error))handler {
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
    [request addResourceWithType:PHAssetResourceTypePhoto fileURL:gifFileUrl options:options];

  } completionHandler:^(BOOL success, NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (handler) {
        handler(success, error);
      }
    });
  }];
}

+ (void)saveLivePhotoToAlbumWithImageFileUrl:(NSURL *)imageUrl videoFileUrl:(NSURL *)videoUrl albumName:(NSString *_Nullable)albumName completionHandler:(void(^)(BOOL success, NSError *error))hander API_AVAILABLE(ios(9.1)) {
  if (albumName) {
    // 需要保存到制定相册
    PHAssetCollection *assetCollection = [[self class] getAssetCollectionWithName:albumName];
    if (!assetCollection) {
      // 创建相册
      [[self class] creatAssetCollectionWithName:albumName completionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
          [[self class] saveLivePhotoDirectWith:imageUrl movUrl:videoUrl addToAlbum:albumName completionHandler:hander];
        } else {
          if (hander) {
            hander(NO, error);
          }
        }
      }];
    } else {
      [[self class] saveLivePhotoDirectWith:imageUrl movUrl:videoUrl addToAlbum:albumName completionHandler:hander];
    }
  } else {
    [[self class] saveLivePhotoDirectWith:imageUrl movUrl:videoUrl addToAlbum:albumName completionHandler:hander];
  }
}

#pragma mark - Save To Album Privete Methods

/**
 保存视频或者图片的基本方法
 */
+ (void)saveDirectWith:(NSURL *)fileUrl isVideo:(BOOL)isVideo albumName:(NSString *)albumName completionHandler:(void(^)(BOOL success, NSError *error))hander {
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHAssetCreationRequest *request = nil;
    if (isVideo) {
      request = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:fileUrl];
    } else {
      request = [PHAssetCreationRequest creationRequestForAssetFromImageAtFileURL:fileUrl];
    }

    if (albumName) {
      PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[[self class] getAssetCollectionWithName:albumName]];
      PHObjectPlaceholder *placeHoler = [request placeholderForCreatedAsset];
      [assetCollectionChangeRequest addAssets:@[placeHoler]];
    }
  } completionHandler:^(BOOL success, NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (hander) {
        hander(success, error);
      }
    });
  }];
}


/**
 保存gif文件到相册的基本方法
 */
+ (void)saveGifDirectWithFileUrl:(NSURL *)gifFileUrl addToAlbum:(NSString *)albumName completionHandler:(void (^)(BOOL success, NSError *error))handler {
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
    [request addResourceWithType:PHAssetResourceTypePhoto fileURL:gifFileUrl options:options];

    if (albumName) {
      PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[[self class] getAssetCollectionWithName:albumName]];
      PHObjectPlaceholder *placeHoler = [request placeholderForCreatedAsset];
      [assetCollectionChangeRequest addAssets:@[placeHoler]];
    }
  } completionHandler:^(BOOL success, NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (handler) {
        handler(success, error);
      }
    });
  }];
}

+ (void)saveLivePhotoDirectWith:(NSURL *)imageUrl movUrl:(NSURL *)movUrl addToAlbum:(NSString *)albumName
        completionHandler:(void (^)(BOOL success, NSError *error))hander API_AVAILABLE(ios(9.1)) {

  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];

    [request addResourceWithType:PHAssetResourceTypePairedVideo
                         fileURL:movUrl
                         options:nil];

    [request addResourceWithType:PHAssetResourceTypePhoto
                         fileURL:imageUrl
                         options:nil];

    if (albumName) {
      PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[[self class] getAssetCollectionWithName:albumName]];

      PHObjectPlaceholder *placeHoler = [request placeholderForCreatedAsset];

      [assetCollectionChangeRequest addAssets:@[placeHoler]];
    }
  } completionHandler:^(BOOL success, NSError * error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (hander) {
        hander(success, error);
      }
    });
  }];
}


@end
