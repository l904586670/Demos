//
//  ViewController.swift
//  SwiftMetal-01
//
//  Created by Rock on 2020/7/20.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  func setupUI() {
    let metalView = MetalView.init(frame: self.view.bounds)
    self.view.addSubview(metalView)
  }


}

