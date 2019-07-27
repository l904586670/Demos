//
//  MetalBaseView.m
//  LearnMatelDemo
//
//  Created by User on 2019/7/23.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "MetalBaseView.h"

#import "MetalLoadTextureTool.h"

@interface MetalBaseView () <MTKViewDelegate>

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, assign) NSInteger vertexNumber;
@property (nonatomic, strong) id<MTLTexture> texture;

@end

@implementation MetalBaseView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    
    [self initiatizeMatel];
    
    [self setupPipeline];
    
    [self loadModelData];
  }
  return self;
}

- (void)initiatizeMatel {
  // get the Dvice
  _device = MTLCreateSystemDefaultDevice();
  if (!_device) {
    NSAssert(NO, @"current device GPU not support Metal");
  } else {
    NSLog(@"current GPU name : %@", _device.name);
  }
  
  // Create a CommandQueue
  _commandQueue = [_device newCommandQueue];
  
  _mtkView = [[MTKView alloc] initWithFrame:self.bounds device:_device];
  _mtkView.clearColor = MTLClearColorMake(1, 1, 1, 1.0);
  _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
  _mtkView.delegate = self;
  [self addSubview:_mtkView];
  
  _viewportSize = (vector_uint2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
}

typedef struct
{
  vector_float4 position;
  vector_float2 textureCoord;
} Vertex_img;

- (void)loadModelData {
  
  
//  顶点坐标范围 [-1, 1]. float  纹理坐标范围 [0, 1], 纹理默认是反转的
  // x, y, z, w,   texture x, y
  static const Vertex_img vertex[] = {
    { {  0.5, -0.5, 0.0, 1.0 },  { 1.f, 1.f } },
    { { -0.5, -0.5, 0.0, 1.0 },  { 0.f, 1.f } },
    { { -0.5,  0.5, 0.0, 1.0 },  { 0.f, 0.f } },

    { {  0.5, -0.5, 0.0, 1.0 },  { 1.f, 1.f } },
    { { -0.5,  0.5, 0.0, 1.0 },  { 0.f, 0.f } },
    { {  0.5,  0.5, 0.0, 1.0 },  { 1.f, 0.f } },
  };
  
  // buffer, texture 可以理解为cpu 和 gpu都可以访问的内存块. 一般为CPU把数据写入buffer, buffer 把数据传给GPU. options 设置资源的管理方式
  self.vertexBuffer = [_device newBufferWithBytes:vertex length:sizeof(vertex) options:MTLResourceStorageModeShared];
  
  self.vertexNumber = sizeof(vertex) / sizeof(Vertex_img);
  
  //
  UIImage *image = [UIImage imageNamed:@"img1.jpg"];
  
  MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
  NSError * error = nil;
  id<MTLTexture> sourceTexture = [textureLoader newTextureWithCGImage:image.CGImage options:nil error:&error];
  self.texture = sourceTexture;

  // 创建纹理描述符
  MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
  textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
  textureDescriptor.width = image.size.width;
  textureDescriptor.height = image.size.height;
  
  self.texture = [_device newTextureWithDescriptor:textureDescriptor];
  MTLRegion region = {{ 0, 0, 0 }, {image.size.width, image.size.height, 1}}; // 纹理上传的范围

  __weak typeof(self) weakSelf = self;
  [MetalLoadTextureTool loadImageWithImage:image conentBlock:^(Byte * _Nonnull imgData, size_t bytesPerRow) {
    [weakSelf.texture replaceRegion:region
                        mipmapLevel:0
                          withBytes:imgData
                        bytesPerRow:bytesPerRow];
  }];
  
}

- (void)setupPipeline {
  id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
  id <MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"imgVertexShader"];
  id <MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"imgFragmentShader"];
  
  // Render Pipeline Descriptors 渲染管道描述符
  /*
   Vertex Layout
   Descriptor
   Vertex Shader
   Fragment Shader
   Blending
   Framebuffer Formats
   */
  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  
  // 描述顶点和颜色位置和偏移量
  MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
  vertexDescriptor.attributes[0].offset = 0;
  vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4; // position
  vertexDescriptor.attributes[0].bufferIndex = 0;
  
  vertexDescriptor.attributes[1].offset = sizeof(float) * 4; // 16
  vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2; // texCoords
  vertexDescriptor.attributes[1].bufferIndex = 0;
  
  vertexDescriptor.layouts[0].stepRate = 1;
  vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
  vertexDescriptor.layouts[0].stride = sizeof(Vertex_img);
  
  pipelineStateDescriptor.vertexDescriptor = vertexDescriptor;
  
  // 顶点描述
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
  pipelineStateDescriptor.vertexFunction = vertexFunc;
  pipelineStateDescriptor.fragmentFunction = fragmentFunc;
  
  NSError *error = nil;
  _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
  if (error) {
    NSAssert(NO, @"creat pipelineState Error : %@", error.description);
  }
}

- (void)render {
  // Get a command buffer 每次渲染都要单独创建一个CommandBuffer
  id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
  
  // Start a Render Pass
  MTLRenderPassDescriptor *renderPassDescriptor = [_mtkView currentRenderPassDescriptor];
  /*
   MTLRenderPassDescriptor
   Color Attachment 0
   Color Attachment 1
   Color Attachment 2
   Color Attachment 3
   Depth Attachment
   Stencil Attachment
   */
  //  MTLRenderPassDescriptor描述一系列attachments的值，类似GL的FrameBuffer；同时也用来创建MTLRenderCommandEncoder
  if(renderPassDescriptor) {
    
    renderPassDescriptor.colorAttachments[0].texture = self.mtkView.currentDrawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1.0f); // 设置渲染的背景颜色
    
    // Draw
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; //编码绘制指令的Encoder
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }]; // 设置显示区域
    [renderEncoder setRenderPipelineState:_pipelineState]; // 设置渲染管道，以保证顶点和片元两个shader会被调用
    
    // 把数据传给顶点描述shader 方法, self.vertices 整个数据内容. offset 偏移, atIndex 设置的buffer 索引, 设为0对应vertex shader 里面的 [[ buffer(0) ]] . 从0 开始
    [renderEncoder setVertexBuffer:_vertexBuffer
                            offset:0
                           atIndex:0]; // 设置顶点缓存
    
    [renderEncoder setFragmentTexture:self.texture atIndex:0];
    
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:self.vertexNumber]; // 绘制
    
    [renderEncoder endEncoding]; // 结束
    
    //Committing a CommandBuffer
    [commandBuffer presentDrawable:_mtkView.currentDrawable]; // 显示
    [commandBuffer commit];
  } else {
    
    // Commit the command buffer
    [commandBuffer commit]; // 提交；
  }
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
  _viewportSize = (vector_uint2){size.width, size.height};
}

- (void)drawInMTKView:(nonnull MTKView *)view {
  
  [self render];
}

#pragma mark - Private Methods

- (void)loadImage:(UIImage *)image content:(void(^)(Byte *imgData, size_t bytesPerRow))contentBlock {
  // 1获取图片的CGImageRef
  CGImageRef spriteImage = image.CGImage;
  
  // 2 读取图片的大小
  size_t width = CGImageGetWidth(spriteImage);
  size_t height = CGImageGetHeight(spriteImage);
  
  size_t bitsPerComponent = CGImageGetBitsPerComponent(spriteImage);  //
  size_t bytesPerRow = CGImageGetBytesPerRow(spriteImage);    //
  
  Byte *spriteData = (Byte *)calloc(height * bytesPerRow, sizeof(Byte)); //rgba共4个byte
  
  CGContextRef spriteContext = CGBitmapContextCreate(spriteData,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     CGImageGetColorSpace(spriteImage),
                                                     kCGImageAlphaPremultipliedLast);
  if (!spriteContext) {
    free(spriteData);
    return;
  }
  
  // 3在CGContextRef上绘图
  CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
  CGContextRelease(spriteContext);
  
  if (contentBlock) {
    contentBlock(spriteData, bytesPerRow);
  }
  
  free(spriteData);
  spriteData = NULL;
}



@end
