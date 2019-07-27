//
//  MetalLoadTextureTool.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/26.
//  Copyright © 2019 Rock. All rights reserved.
//
// https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Mem-Obj/Mem-Obj.html#//apple_ref/doc/uid/TP40014221-CH4-SW17

#import "MetalLoadTextureTool.h"

static const size_t kBitsPerComponent = 8;
static const size_t kBytesPerPixel = 4;
static const CGBitmapInfo kBitmapInfoBGRA8Unorm = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little;

@implementation MetalLoadTextureTool

+ (id<MTLTexture>)textureWithImage:(UIImage *)image device:(id<MTLDevice>)device {
  if (!image) {
    NSAssert(NO, @"creat texture image can not be nil");
    return nil;
  }
  NSParameterAssert(device);
  
  size_t width = image.size.width;
  size_t height = image.size.height;
  
  // 创建默认的纹理描述对象
  MTLTextureDescriptor *descriptor = [[self class] textureDescriptorWithWidth:width height:height];
  
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
  
  descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
  
  // mipmap 为了加快渲染速度和减少图像锯齿，贴图被处理成由一系列被预先计算和优化过的图片组成的文档,这样的贴图被称为 MIP map 或者 mipmap。这个技术在三维游戏中被非常广泛的使用
  descriptor.mipmapLevelCount = 1; // default 1
  descriptor.sampleCount = 1; // 指定每个像素中的样本数。 default 1
  descriptor.arrayLength = 1; // 指定一个MTLTextureType1DArray或MTLTextureType2DArray类型纹理对象的数组元素的数量 default 1
//  descriptor.resourceOptions = MTLResourceOptionCPUCacheModeDefault; // 指定其内存分配的行为
  
  /*
  Shared Storage：CPU 和 GPU 均可读写这块内存。
  Private Storage: 仅 GPU 可读写这块内存，可以通过 Blit 命令等进行拷贝。
  Managed Storage: 仅在 macOS 中允许。仅 GPU 可读写这块内存，但 Metal 会创建一块镜像内存供 CPU 使用。
   */
  descriptor.storageMode = MTLStorageModeShared;
  
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

@end
