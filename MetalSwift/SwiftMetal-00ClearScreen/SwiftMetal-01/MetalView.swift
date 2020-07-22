//
//  MetalView.swift
//  SwiftMetal-01
//
//  Created by Rock on 2020/7/20.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

class MetalView: UIView {
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  var metalLayer : CAMetalLayer {
    return layer as! CAMetalLayer
  }

  override class var layerClass: AnyClass {
    return CAMetalLayer.self
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()

    render()
  }

// MARK: private
///  初始化环境
  func commonInit() {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("gpu is not supported")
    }
    print("device name : \(device.name)")
    commandQueue = device.makeCommandQueue()
  }

  func render() -> () {
    guard let drawable = metalLayer.nextDrawable() else { return
    }
    // 渲染管道描述符
    let renderPassDescripor = MTLRenderPassDescriptor()
    renderPassDescripor.colorAttachments[0].clearColor = MTLClearColorMake(0.48, 0.74, 0.92, 1.0)
    renderPassDescripor.colorAttachments[0].texture = drawable.texture
    renderPassDescripor.colorAttachments[0].loadAction = .clear
    renderPassDescripor.colorAttachments[0].storeAction = .store

    // 提交一次buffer
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescripor)!
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
