//
//  HomeViewController.swift
//  LayerEliminate
//
//  Created by Rock on 2020/7/23.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    var models: [LevelModel]! = []
    var playView: GamePlayView!


    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white

        loadData()

        setupUI()
    }

    private func setupUI() {

        playView = GamePlayView.init(frame: CGRect.init(x: 0, y: 50, width: self.view.frame.width, height: self.view.frame.width))
        self.view.addSubview(playView)

        playView?.startGameFromData(model: models[0])
    }

    private func loadData() {
        if let file = Bundle.main.path(forResource: "level", ofType: "conf") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: file))
                let json:Array<Dictionary<String, Any>> = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! Array<Dictionary<String, Any>>
                models = dictToModels(list: json)
                print("\(json)")
            } catch {
                print("read conf fail")
            }
        } else {
            fatalError("level.conf file not exsited")
        }
    }

    private func dictToModels(list:[[String:Any]]) -> [LevelModel] {
        var models = [LevelModel]()
        for dict in list {
            models.append(LevelModel.init(dict: dict))
        }
        return models
    }

}

