//
//  YiquxPhotosUtility.h
//
//  Created by Rock on 2019/1/15.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YiquxPhotosUtility : NSObject

#pragma mark - Delete Album Asset

/**
 删除设备相册资源文件

 @param phAsset 相册资源
 @param handler 结果回调
 */
+ (void)deletePhAsset:(PHAsset *)phAsset
        resultHandler:(void(^)(BOOL success, NSError *error))handler;

#pragma mark - Write To Sandbox

/**
 把 livePhoto资源写入到沙盒中

 @param asset livePhoto 资源文件
 @param videoUrl 导出的视频url
 @param imgUrl 导出的封面图片url
 @param handler 结果回调
 */
+ (void)writeLivePhotoToSandboxWithAsset:(PHAsset *)asset
                          videoOutputUrl:(NSURL * _Nullable)videoUrl
                            imgOutputUrl:(NSURL * _Nullable)imgUrl
                           resultHandler:(void(^)(BOOL success, NSURL *videoOutputUrl, NSURL *imgOutputUrl, NSError *error))handler;

#pragma mark - Request Album Data

/**
 请求一组图片

 @param results results
 @param hander 回调结果
 */
+ (void)asynchRequestImagesWith:(PHFetchResult<PHAsset *> *)results
              completionHandler:(void(^)(NSArray *sortImages))hander;


+ (NSArray <UIImage *>*)imagesWithImageAssets:(NSArray <PHAsset *>*)results;

/**
 请求连拍照片合集. 连拍照片由一组照片组成.获取每一张照片

 @param asset 连拍资源
 @return 连拍照片
 */
+ (PHFetchResult<PHAsset *> *)requestBurstResultWithAsset:(PHAsset *)asset;


/**
 请求LivePhoto 资源

 @param asset livePhoto 资源
 @param handler 回调
 @return 请求ID
 */
+ (PHImageRequestID)requestLivePhotoWithAsset:(PHAsset *)asset
                                resultHandler:(void(^)(PHLivePhoto *livePhoto, NSDictionary * info))handler API_AVAILABLE(ios(9.1));


/**
 请求livePhoto资源的视频文件

 @param asset livePhoto PHAsset
 @param handler asset, fileUrl 沙盒Url
 */
+ (void)requestLivePhotoResourceVideoWith:(PHAsset *)asset
                            resultHandler:(void (^)(AVAsset *asset, NSURL *fileUrl))handler API_AVAILABLE(ios(9.1));

/**
 视频资源 由PHAsset类型转换为 AVAsset 类型

 @param asset asset
 @param handler 回调
 @return 请求ID
 */
+ (PHImageRequestID)requestVideoAssetWithAsset:(PHAsset *)asset
                                 resultHandler:(void (^)(AVAsset * asset, AVAudioMix *audioMix, NSDictionary * info))handler;

/**
 异步请求资源原图

 @param asset 资源
 @param handler 请求回调
 @return 请求ID .可以取消请求
 */
+ (NSInteger)asynchRequestAssetOriginalImageWithAsset:(PHAsset *)asset
                                    completionHandler:(void(^)(UIImage *originalImage, NSDictionary * info))handler;

/**
 异步请求资源缩略图

 @param asset 资源
 @param targetSize 请求尺寸,一般为itemSize * Screen.scale. 填CGSizeZero 使用默认
 @param handler 请求回调
 @return 请求ID .可以取消请求 也可在回调里面 info[PHImageResultRequestIDKey] 判断图片
 */
+ (NSInteger)asynchRequestAssetThumbnailWithAsset:(PHAsset *)asset
                                       targetSize:(CGSize)targetSize
                                completionHandler:(void (^)(UIImage *result, NSDictionary *info))handler;

/**
 获取 剔除了延时摄影和慢动作视频的视频集合

 @return 视频集合
 */
+ (PHFetchResult<PHAsset *> *)filterVideoAsset;

/**
 获取指定具体图片类型的asset集合 (只可以获取 全景, HDR, 截屏, LivePhoto, 人像)类型 .
 获取连拍数据 需要获取连拍相册,根据连拍相册取连拍集合

 @param mediaSubtype 传入 PHAssetMediaSubtypeNone 获取所有图片
 @return asset 集合
 */
+ (PHFetchResult<PHAsset *> *)imageAssetResultWithMediaSubtype:(PHAssetMediaSubtype)mediaSubtype;

/**
 筛选指定相册的资源, 返回制定类型资源

 @param assetCollection 指定相册
 @param mediaType 视频/图片
 @return 资源集合
 */
+ (PHFetchResult<PHAsset *> *)filterAssetsWithAssetCollection:(PHAssetCollection *)assetCollection mediaType:(PHAssetMediaType)mediaType;

/**
 同步获取指定相册的封面图.

 @param assetCollection 相册
 @param targetSize 获取图片的size.size的大小影响返回图片的清晰度. 填CGSizeZero返回屏幕宽度1/3大小
 @return 相册封面图
 */

+ (UIImage *)synchRequestCollectionThumbnailWith:(PHAssetCollection *)assetCollection
                                      targetSize:(CGSize)targetSize;

+ (UIImage *)synchRequestCollectionThumbnailWith:(PHAssetCollection *)assetCollection
                                      targetSize:(CGSize)targetSize
                                       mediaType:(PHAssetMediaType)mediaType;

/**
 获取指定资源类型的相册集合

 @param mediaType 图片/视频/音频/未知
 @return 相册数组
 */
+ (NSArray <PHCollection *>*)getNormalCollectionWithMediaType:(PHAssetMediaType)mediaType;


/**
 获取用户设备里面的指定资源, 具体类型的所有相册

 @param mediaType 图片/视频/音频/未知
 @param subType 指定类型
 @return 相册数组
 */
+ (NSArray <PHCollection *>*)getUserCollectionWithMediaType:(PHAssetMediaType)mediaType
                                                    subType:(PHAssetCollectionSubtype)subType;


+ (NSString *)timeFormattedWithVideoAsset:(PHAsset *)asset;

#pragma mark - Creat Custom Album

+ (NSString *)appDisplayName;

+ (void)creatAssetCollectionWithName:(NSString *)albumName
                   completionHandler:(void(^)(BOOL success, NSError *error))hander;


#pragma mark - Save File To Album
// 所有要保存到相册的文件都必须存在本地沙盒中, 不能够嵌套保存?

+ (void)saveImageToAlbumWithFileUrl:(NSURL *)fileUrl
                          albumName:(NSString *_Nullable)albumName
                  completionHandler:(void(^)(BOOL success, NSError *error))hander;

+ (void)saveVideoToAlbumWithFileUrl:(NSURL *)fileUrl
                          albumName:(NSString *_Nullable)albumName
                  completionHandler:(void(^)(BOOL success, NSError *error))hander;

+ (void)saveAudioToAlbumWithFileUrl:(NSURL *)fileUrl completionHandler:(void(^)(BOOL success, NSError *error))handler;

+ (void)saveGifToAlbumWithFileUrl:(NSURL *)gifFileUrl
                completionHandler:(void (^)(BOOL success, NSError * error))handler;

+ (void)saveLivePhotoToAlbumWithImageFileUrl:(NSURL *)imageUrl
                                videoFileUrl:(NSURL *)videoUrl
                                   albumName:(NSString *_Nullable)albumName
                           completionHandler:(void(^)(BOOL success, NSError *error))hander API_AVAILABLE(ios(9.1));

@end

NS_ASSUME_NONNULL_END
