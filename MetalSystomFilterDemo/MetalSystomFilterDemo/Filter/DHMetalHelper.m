//
//  DHMetalHelper.m
//  PaintByMetalDemo
//
//  Created by User on 2019/8/5.
//  Copyright © 2019 Rock. All rights reserved.
//

// https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Mem-Obj/Mem-Obj.html#//apple_ref/doc/uid/TP40014221-CH4-SW17

#import "DHMetalHelper.h"

#import <MetalKit/MetalKit.h>

// 
static const size_t kBitsPerComponent = 8;
static const size_t kBytesPerPixel = 4;
static const CGBitmapInfo kBitmapInfoBGRA8Unorm = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;
/*
 CGImageByteOrderInfo | CGImageAlphaInfo 组合后CGBitmapInfo 的颜色空间的格式
 
         CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaLast; // 像素存储格式0xABGR 像素类型RGBA
 
         CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaFirst; // 像素存储格式0xBGRA 像素类型ARGB
 
         CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaLast; // 像素存储格式0xRGBA 像素类型RGBA
 
         CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaFirst; // 像素存储格式0xARGB 像素类型ARGB
https://blog.csdn.net/jeffasd/article/details/80571366
 */

@implementation DHMetalHelper

#pragma mark - Load Texture

// MetalKit 里面的加载纹理的方法
+ (id<MTLTexture>)loaderTextureWithImage:(UIImage *)image device:(id<MTLDevice>)device {
  MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:device];
  // 默认是打开的, 会导致颜色和原图有误差
  NSDictionary *option = @{
                           MTKTextureLoaderOptionSRGB : [NSNumber numberWithBool:NO]
                           };
  return [loader newTextureWithCGImage:image.CGImage options:option error:nil];
}


+ (id<MTLTexture>)textureWithImage:(UIImage *)image device:(id<MTLDevice>)device {
  return [[self class] textureWithImage:image device:device usage:MTLTextureUsageUnknown];
}

+ (id<MTLTexture>)textureWithImage:(UIImage *)image
                            device:(id<MTLDevice>)device
                             usage:(MTLTextureUsage)textureUsage {
  if (!image) {
    NSAssert(NO, @"creat texture image can not be nil");
    return nil;
  }
  NSParameterAssert(device);
  
  size_t width = image.size.width;
  size_t height = image.size.height;
  
  // 创建默认的纹理描述对象
  MTLTextureDescriptor *descriptor = [[self class] textureDescriptorWithWidth:width height:height];
  descriptor.usage = textureUsage;
  
  // 为纹理图像数据开辟一个新的内存空间并创建一个 MTLTexture 对象，它将根据传入的 MTLTextureDescriptor 对象设置此纹理的属性
  id <MTLTexture>texture = [device newTextureWithDescriptor:descriptor];
  
  [[self class] loadImageWithImage:image conentBlock:^(Byte * _Nonnull imgData, size_t bytesPerRow) {
    // 将图像数据复制到纹理中, Metal 不会翻转纹理，原点在左上角，OpenGL 的原点是左下角
    MTLRegion region = {
      { 0, 0, 0 },        // MTLOrigin
      {width, height, 1}  // MTLSize
    };
    [texture replaceRegion:region
               mipmapLevel:0
                 withBytes:imgData
               bytesPerRow:bytesPerRow];
  }];
  
  return texture;
}


+ (id<MTLTexture>)emptyTextureWithWidth:(NSUInteger)width
                                 height:(NSUInteger)height
                                 device:(id<MTLDevice>)device {
  return [[self class] emptyTextureWithWidth:width
                                      height:height
                                      device:device
                                       usage:MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget];
}

+ (id<MTLTexture>)emptyTextureWithWidth:(NSUInteger)width
                                 height:(NSUInteger)height
                                 device:(id<MTLDevice>)device
                                  usage:(MTLTextureUsage)usage {
  NSParameterAssert(device);
  
  // 空纹理一般会用来写入内容
  MTLTextureDescriptor *descriptor = [[self class] textureDescriptorWithWidth:width height:height];
  descriptor.usage = usage;
  return [device newTextureWithDescriptor:descriptor];
}

+ (MTLTextureDescriptor *)textureDescriptorWithWidth:(NSUInteger)width height:(NSUInteger)height {
  // 描述要创建的纹理的属性.
  MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
  descriptor.textureType = MTLTextureType2D;  // 指定纹理的维度和排列 default:MTLTextureType2D
  descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;  // 指定像素在纹理中的存储方式 default MTLPixelFormatRGBA8Unorm
  /*
   的width，height和depth属性在基级纹理的mipmap的每个维度指定像素大小。
   */
  descriptor.width = width;
  descriptor.height = height;
  
//  descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
  
  // mipmap 为了加快渲染速度和减少图像锯齿，贴图被处理成由一系列被预先计算和优化过的图片组成的文档,这样的贴图被称为 MIP map 或者 mipmap。这个技术在三维游戏中被非常广泛的使用
  //  descriptor.mipmapLevelCount = 1; // default 1
  //  descriptor.sampleCount = 1; // 指定每个像素中的样本数。 default 1
  //  descriptor.arrayLength = 1; // 指定一个MTLTextureType1DArray或MTLTextureType2DArray类型纹理对象的数组元素的数量 default 1
  //  descriptor.resourceOptions = MTLResourceOptionCPUCacheModeDefault; // 指定其内存分配的行为
  
  /*
   Shared Storage：CPU 和 GPU 均可读写这块内存。
   Private Storage: 仅 GPU 可读写这块内存，可以通过 Blit 命令等进行拷贝。
   Managed Storage: 仅在 macOS 中允许。仅 GPU 可读写这块内存，但 Metal 会创建一块镜像内存供 CPU 使用。
   */
  //  descriptor.storageMode = MTLStorageModeShared;
  
  return descriptor;
}

// 一般纹理texture格式为  MTLPixelFormatBGRA8Unorm

+ (void)loadImageWithImage:(UIImage *)textureImage conentBlock:(void(^)(Byte *imgData, size_t bytesPerRow))handler {
  if (!textureImage) {
    NSAssert(NO, @"Not found texture image");
    return;
  }
  
  /**
   为了最后到处imageData 符合 PixelFormatBGRA8Unorm格式
   除了取imageSize. 其他数值固定. 这样可以避免jpg图片alpha通道数据为0问题导致纹理和原图不一致
   */
  CGImageRef imageRef = textureImage.CGImage;
  size_t width = CGImageGetWidth(imageRef);
  size_t height = CGImageGetHeight(imageRef);
  size_t bytesPerRow = width * kBytesPerPixel;
  
  Byte *imageData = (Byte *)calloc(width * height * kBytesPerPixel, sizeof(Byte));
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  
  CGContextRef bitmapContext = CGBitmapContextCreate(imageData,
                                                     width,
                                                     height,
                                                     kBitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpace,
                                                     kBitmapInfoBGRA8Unorm);

  if (!bitmapContext) {
    free(imageData);
    NSAssert(NO, @"get imageData fail");
    return;
  }
  
  CGContextDrawImage(bitmapContext, CGRectMake(0, 0, width, height), imageRef);
  
  if (handler) {
    handler(imageData, bytesPerRow);
  }
  
  CGColorSpaceRelease(colorSpace);
  CGContextRelease(bitmapContext);
  free(imageData);
  imageData = NULL;
}

+ (UIImage *)imageFromTexture:(id<MTLTexture>)texture {
  // The total number of bytes of the texture
  NSUInteger imageByteCount = texture.width * texture.height * kBytesPerPixel;
  
  // The number of bytes for each image row
  size_t bytesPerRow = texture.width * kBytesPerPixel;
  
  // An empty buffer that will contain the image
  void *src = calloc(imageByteCount, sizeof(Byte));
//  void *src = malloc(imageByteCount);
  
  // Gets the bytes from the texture
  MTLRegion region = MTLRegionMake2D(0, 0, texture.width, texture.height);
  // 用 没有 slice 的那个方法有时会损失数据
  [texture getBytes:src
        bytesPerRow:bytesPerRow
      bytesPerImage:0
         fromRegion:region
        mipmapLevel:0
              slice:0];

  // Creates an image context
  CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
  if (MTLPixelFormatBGRA8Unorm == texture.pixelFormat) {
    bitmapInfo = kCGImageByteOrder32Little | kCGImageAlphaPremultipliedFirst;
  } else if (MTLPixelFormatRGBA8Unorm == texture.pixelFormat) {
    bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
  } else {
    free(src);
    NSAssert(NO, @"this pixelFormatType is not support");
    return nil;
  }
  
  // Creates the image from the graphics context
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(src, texture.width, texture.height, kBitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
  
  if (!context) {
    NSAssert(NO, @"creat CGContextRef fail");
  }
  
  CGImageRef imageRef = CGBitmapContextCreateImage(context);
  UIImage *resultImg = [UIImage imageWithCGImage:imageRef];
 
  free(src);
  CGColorSpaceRelease(colorSpace);
  CGImageRelease(imageRef);
  
  return resultImg;
}

#pragma mark - MTLRenderPipelineState

+ (id<MTLRenderPipelineState>)renderPipelineStateWithDevice:(id<MTLDevice>)device
                                                 vertexName:(NSString *)vertexName
                                               fragmentName:(NSString *)fragmentName
                                               blendEnabled:(BOOL)blendEnabled {
  id <MTLLibrary> defaultLibrary = [device newDefaultLibrary];
  id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:fragmentName];
  id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:vertexName];
  
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineStateDescriptor.vertexFunction = vertexFunction;
  pipelineStateDescriptor.fragmentFunction = fragmentFunction;
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
  
  pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatInvalid;      // 不启用深度测试
  pipelineStateDescriptor.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;    // 不启用stencil
  if (blendEnabled) {
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
  }
  
  NSError *error = nil;
  id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
  if (error) {
    NSAssert(NO, @"creat render pipelineState Error : %@", error.description);
    return nil;
  }
  return pipelineState;
}

+ (id<MTLComputePipelineState>)computePipelineStateWithDevice:(id<MTLDevice>)device
                                                   kernelName:(NSString *)kernelName {
  id<MTLLibrary> defaultLibrary = [device newDefaultLibrary];
  id<MTLFunction> func = [defaultLibrary newFunctionWithName:kernelName];
  NSError *error = nil;
  id<MTLComputePipelineState> pipelineState = [device newComputePipelineStateWithFunction:func error:&error];
  if (error) {
    NSAssert(NO, @"creat compute pipelineState Error : %@", error.description);
    return nil;
  }
  return pipelineState;
}


#pragma mark - Other

+ (MTLClearColor)clearColorFromColor:(UIColor *)color {
  if (!color) {
    NSAssert(NO, @"color can be nil");
    return MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
  }
  CGFloat r, g, b, a ;
  BOOL result = [color getRed:&r green:&g blue:&b alpha:&a];
  if (result) {
    return MTLClearColorMake(r, g, b, a);
  } else {
    return MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
  }
}



@end
