//
//  ViewController.swift
//  SwiftMetal-01DrawTriangle
//
//  Created by Rock on 2020/7/21.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  var renderView: MetalView!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.

    renderView = MetalView.init(frame: self.view.bounds)
    self.view.addSubview(renderView)

    let transformSwicth = UISwitch.init(frame: CGRect.init(x: 10, y: 100, width: 50, height: 40))
    self.view.addSubview(transformSwicth)
    transformSwicth.addTarget(self, action: #selector(swicthDidChange( _:)), for: .valueChanged)
  }

  @objc func swicthDidChange(_ sender: UISwitch) {
    renderView.changeTransform(sender.isOn)
  }
}

