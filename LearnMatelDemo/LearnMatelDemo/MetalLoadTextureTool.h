//
//  MetalLoadTextureTool.h
//  LearnMatelDemo
//
//  Created by User on 2019/7/26.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalLoadTextureTool : NSObject


/**
 返回一个2d图片纹理. 纹理描述描述属性大部分为默认值

 @param image 纹理图片
 @param device GPU
 @return 纹理对象
 */
+ (id<MTLTexture>)textureWithImage:(UIImage *)image device:(id<MTLDevice>)device;


/**
 从UIImage 中读取图片data数据. 担心忘记释放data 和 bitmapContext colorSpace 所以以block的形式

 @param textureImage 图片
 @param handler 在block 中处理复制图片数据的操作
 */
+ (void)loadImageWithImage:(UIImage *)textureImage
               conentBlock:(void(^)(Byte *imgData, size_t bytesPerRow))handler;

@end

NS_ASSUME_NONNULL_END
