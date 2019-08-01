
#ifndef AVCapturePhotoOutputHeader_h
#define AVCapturePhotoOutputHeader_h

// HEIC格式图片存储效率更高,同样的体积它能存储更多的图像信息内容

/**
 AVCapturePhotoOutput : 从会话流中导出照片
 支持 导出无损RAW(DNG格式), HEVC(HEIF格式), JPEG
 
 使用方法 :
 1. 创建 AVCapturePhotoOutput 对象, 设置一些属性, 如: 开启导出livePhoto
 2. 创建 AVCapturePhotoSettings 对象, 配置一些设置.如开启闪光,自动稳定,防红眼
 3. 调用 capturePhoto(with:delegate:)AVCapturePhotoCaptureDelegate. 在代理中获取图片信息
 
 
 
 availablePhotoFileTypes // 当前支持照片捕获和输出的文件类型列表。
 
 */

#endif /* AVCapturePhotoOutputHeader_h */
