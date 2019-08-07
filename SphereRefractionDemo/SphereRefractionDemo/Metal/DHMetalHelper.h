//
//  DHMetalHelper.h
//  PaintByMetalDemo
//
//  Created by User on 2019/8/5.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface DHMetalHelper : NSObject

#pragma mark - Load Texture

/**
 返回一个用途未知的2d图片纹理. 纹理描述描述属性大部分为默认值
 
 @param image 纹理图片
 @param device GPU
 @return 纹理对象
 */
+ (id<MTLTexture>)textureWithImage:(UIImage *)image
                            device:(id<MTLDevice>)device;


/**
 返回一个指定用途的纹理

 @param image 纹理图片
 @param device 设备GPU
 @param textureUsage 纹理用途 MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget
 @return 纹理对象
 */
+ (id<MTLTexture>)textureWithImage:(UIImage *)image
                            device:(id<MTLDevice>)device
                             usage:(MTLTextureUsage)textureUsage;

/**
 创建一个指定大小的空纹理.

 @param width 宽度
 @param height 长度
 @param device 设备
 @return 纹理对象
 */
+ (id<MTLTexture>)emptyTextureWithWidth:(NSUInteger)width
                                 height:(NSUInteger)height
                                 device:(id<MTLDevice>)device;

+ (id<MTLTexture>)emptyTextureWithWidth:(NSUInteger)width
                                 height:(NSUInteger)height
                                 device:(id<MTLDevice>)device
                                  usage:(MTLTextureUsage)usage;

/**
 从UIImage 中读取图片data数据. 担心忘记释放data 和 bitmapContext colorSpace 所以以block的形式
 
 @param textureImage 图片
 @param handler 在block 中处理复制图片数据的操作
 */
+ (void)loadImageWithImage:(UIImage *)textureImage
               conentBlock:(void(^)(Byte *imgData, size_t bytesPerRow))handler;

// 从纹理中获取图片
+ (UIImage *)imageFromTexture:(id<MTLTexture>)texture;

#pragma mark - PipelineState Methods


/**
 创建渲染管道状态

 @param device 设备
 @param vertexName 顶点方法名称
 @param fragmentName 片段方法名称
 @param blendEnabled 是否融合
 @return 渲染管道状态对象
 */
+ (id<MTLRenderPipelineState>)renderPipelineStateWithDevice:(id<MTLDevice>)device
                                                 vertexName:(NSString *)vertexName
                                               fragmentName:(NSString *)fragmentName
                                               blendEnabled:(BOOL)blendEnabled;

// 创建compute管道状态
+ (id<MTLComputePipelineState>)computePipelineStateWithDevice:(id<MTLDevice>)device
                                                   kernelName:(NSString *)kernelName;

#pragma mark - Other

+ (MTLClearColor)clearColorFromColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
