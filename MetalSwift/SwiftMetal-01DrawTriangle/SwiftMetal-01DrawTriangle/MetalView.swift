//
//  MetalView.swift
//  SwiftMetal-01DrawTriangle
//
//  Created by Rock on 2020/7/21.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

class MetalView: UIView {
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  var vertices: MTLBuffer!
  var numVertices: Int!
  var pipelineState: MTLRenderPipelineState!
  var time: Float!
  var transformFlag: Bool = false

  var metalLayer : CAMetalLayer {
    return layer as! CAMetalLayer
  }

  override class var layerClass: AnyClass {
    return CAMetalLayer.self
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initMetalConfig()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    initMetalConfig()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    render()
  }

  // MARK: private
  func initMetalConfig() {
    device = MTLCreateSystemDefaultDevice()
    guard device !== nil else {
      fatalError("gpu is not supported")
    }

    print("device name : \(device.name)")

    // creat commandQueue 创建command Queue(异步串行线程). 用于获取当前的 commandBuffer 并提交给GPU
    commandQueue = device.makeCommandQueue()

    //
    metalLayer.pixelFormat = .bgra8Unorm

    // load model

    // x,y,z,w, r,g,b,a
    let vertexs = [
      YLZVertex(position: [0.5,  -0.5, 0.0, 1.0], color: [1.0,   0,  0,  1]),
      YLZVertex(position: [-0.5, -0.5, 0.0, 1.0], color: [0.0, 1.0,  0,  1]),
      YLZVertex(position: [0,     0.5, 0.0, 1.0], color: [0.0, 0.0, 1.0, 1])
    ]
    numVertices = MemoryLayout<YLZVertex>.size

    vertices = device.makeBuffer(bytes: vertexs, length: MemoryLayout<YLZVertex>.size * 3, options:.storageModeShared)

    setupPipeline()

    time = 0.0
    let displayLink = CADisplayLink.init(target: self, selector: #selector(updateRenderFrame(_:)))
    displayLink.add(to: RunLoop.current, forMode: .common)
  }

  func setupPipeline() {
    let defaultLibrary = device.makeDefaultLibrary()
    let vertexFunc = defaultLibrary?.makeFunction(name: "vertexShader")
    let fragmentFunc = defaultLibrary?.makeFunction(name: "fragmentShader")
      // Render Pipeline Descriptors 渲染管道描述符
      /*
      Vertex Layout
      Descriptor
      Vertex Shader
      Fragment Shader
      Blending
      Framebuffer Formats
       */
    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()

    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].format = .float4
    vertexDescriptor.attributes[0].bufferIndex = 0

    vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD4<Float>>.size
    vertexDescriptor.attributes[1].format = .float4
    vertexDescriptor.attributes[1].bufferIndex = 0

    // 如果有纹理信息, 添加纹理信息
       //  vertexDescriptor.attributes[2].offset = 24
       //  vertexDescriptor.attributes[2].format = MTLVertexFormatFloat2; // texCoords
       //  vertexDescriptor.attributes[2].bufferIndex = 0

    vertexDescriptor.layouts[0].stepRate = 1
    vertexDescriptor.layouts[0].stepFunction = .perVertex
    vertexDescriptor.layouts[0].stride = MemoryLayout<YLZVertex>.size

    pipelineStateDescriptor.vertexDescriptor = vertexDescriptor

      // 顶点描述
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
    pipelineStateDescriptor.vertexFunction = vertexFunc
    pipelineStateDescriptor.fragmentFunction = fragmentFunc

    pipelineState = try!device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
  }

  public func changeTransform(_ switchFlag:Bool) {
    transformFlag = switchFlag
  }

  /**
   渲染, 获取 commandBuffer , 创建渲染描述符
   创建渲染编码器, 设置数据,确定绘画类型,结束编码
   加载到currentDrawAble上. 提交此次buffer
   */
  func render() {
    guard let drawable = metalLayer.nextDrawable() else { return
    }
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0)
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear

    let commandBuffer = commandQueue.makeCommandBuffer()!

    let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    commandEncoder.setRenderPipelineState(pipelineState)

    commandEncoder.setVertexBuffer(self.vertices, offset: 0, index: 0)

    var uniMatrix = float4x4.init(scaling: 1)
    if transformFlag {
      time += 0.05
      let dx = sin(time)
      let dy = cos(time)
      uniMatrix.columns.0.w = dx
      uniMatrix.columns.1.w = dy
    } 

    commandEncoder.setVertexBytes(&uniMatrix, length: MemoryLayout<float4x4>.size, index: 1)

    commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)
    commandEncoder.endEncoding()

    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  @objc func updateRenderFrame(_ displayLink: CADisplayLink) {
    render()
  }
}
