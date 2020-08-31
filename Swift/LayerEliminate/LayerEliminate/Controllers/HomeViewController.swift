//
//  HomeViewController.swift
//  LayerEliminate
//
//  Created by Rock on 2020/7/23.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, GamePlayViewDelegate {
    
    
    var models: [LevelModel]! = []
    var playView: GamePlayView!
    var targetView: GamePlayView!
    var levelIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white

        loadData()

        setupUI()
    }

    private func setupUI() {
        let statusRect = UIApplication.shared.statusBarFrame
        let screenWidth = UIScreen.main.bounds.size.width
        let playRect = CGRect.init(x: 0, y: statusRect.maxY + 10, width: screenWidth, height: screenWidth)
        
        playView = GamePlayView.init(frame: playRect)
        playView.delegate = self
        self.view.addSubview(playView)
        playView.startGame(from: models[levelIndex], isDest: false)
        
        
        let targetW = screenWidth/2.0
        let targetRect = CGRect.init(x: (screenWidth - targetW)/2.0, y: playRect.maxY + 30, width: targetW, height: targetW)
        
        targetView = GamePlayView.init(frame: targetRect)
        targetView.matrixCount = 11
        targetView.isUserInteractionEnabled = false
        self.view.addSubview(targetView)
        targetView.startGame(from: models[levelIndex], isDest: true)
        
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

    func gamePlayViewDidCompeteLevel(level: Int8) {
        let alert = UIAlertController.init(title: "恭喜", message: "进入下一关", preferredStyle:.alert)
        let nextLevelAction = UIAlertAction.init(title: "下一关", style: .default) { (nextAction) in
            self.levelIndex+=1
            self.playView.startGame(from: self.models[self.levelIndex], isDest: false)
            self.targetView.startGame(from: self.models[self.levelIndex], isDest: true)
        }
        let cancelAction = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
        alert.addAction(nextLevelAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
}

