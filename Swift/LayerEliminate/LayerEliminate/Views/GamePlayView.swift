//
//  GamePlayView.swift
//  LayerEliminate
//
//  Created by Rock on 2020/7/24.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

import AVFoundation
import CoreGraphics

protocol GamePlayViewDelegate  {
    func gamePlayViewDidCompeteLevel(level:Int8)
}

class GamePlayView: UIView, EliminateViewDelegate {
    
    /// 边界间隙
    var paddingInset: UIEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
    
    var delegate: GamePlayViewDelegate?
    
    var matrixWH: Int = 15
    /// 矩阵点
    var matrixCount: Int {
        get {
            return matrixWH
        }
        set {
            matrixWH = newValue
            creatMatrix()
        }
    }
    
    var bottomShapLayer: CAShapeLayer!
    
    var pointBgLayer: CALayer!
    
    var itemSpacing: CGFloat = 0.0
    
    var contentPointArray: [Any] = []
    
    var originPoint: CGPoint = CGPoint.zero
    
    var items: [EliminateView]! = []

    var levelModel: LevelModel?
    
    var touchSoundEffect: AVAudioPlayer? {
        get {
            if let filePath = Bundle.main.path(forResource: "touch", ofType: "mp3") {
                let url = URL.init(fileURLWithPath: filePath)
                do {
                    let soundEffect = try AVAudioPlayer(contentsOf: url)
                    return soundEffect
                } catch {
                    return nil
                }
            } else {
                fatalError("can not found file [touch.mp3] in bundle")
            }
            return nil
        }
    }
    

    //MARK: override
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
    }
    
    // MARK: UI
    private func setupUI() {
        // 底层layer
        bottomShapLayer = CAShapeLayer()
        bottomShapLayer?.frame = self.bounds
        bottomShapLayer?.backgroundColor = UIColor.white.cgColor
        bottomShapLayer?.lineWidth = 0.0
        bottomShapLayer?.lineCap = .round
        bottomShapLayer?.lineJoin = .round
        bottomShapLayer?.fillColor = UIColor.black.cgColor
        bottomShapLayer?.fillRule = .evenOdd
        self.layer.addSublayer(bottomShapLayer)
        
        pointBgLayer = CALayer()
        pointBgLayer?.frame = self.bounds
        pointBgLayer?.backgroundColor = UIColor.clear.cgColor
        self.layer.addSublayer(pointBgLayer)
        
        creatMatrix()
    }
    
    private func creatMatrix() {
        let contentW = self.bounds.width - paddingInset.left - paddingInset.right
        let contentH = self.bounds.height - paddingInset.top - paddingInset.bottom
        var minWH = min(contentW, contentH)
        itemSpacing = floor(minWH/CGFloat((matrixCount - 1)))
        minWH = itemSpacing * CGFloat((matrixCount - 1))
        let firstPosX = round((self.bounds.width - minWH)/2.0)
        let firstPosY = round((self.bounds.height - minWH)/2.0)
        let firstPoint = CGPoint.init(x: firstPosX, y: firstPosY)
        
        originPoint = firstPoint
        
        // draw point
        contentPointArray.removeAll()
        
        let dotSublayers: Array<CALayer> = pointBgLayer.sublayers ?? []
        if (dotSublayers.count > 0) {
            for sublayer in pointBgLayer.sublayers! where sublayer is CAShapeLayer {
                sublayer.removeFromSuperlayer()
            }
        }

        for x in 0...matrixCount - 1 {
            var items: Array<CGPoint> = []
            for y in 0...matrixCount - 1 {
                let offsetX = CGFloat(x) * itemSpacing
                let offsetY = CGFloat(y) * itemSpacing
                
                let point = firstPoint.offset(offsetX: offsetX, offsetY: offsetY)
                items.append(point)
                
                let dotLayer = CAShapeLayer()
                dotLayer.backgroundColor = UIColor.lightGray.cgColor
                dotLayer.bounds = CGRect.init(x: 0, y: 0, width: 5, height: 5)
                dotLayer.cornerRadius = 5.0/2.0
                dotLayer.position = point
                pointBgLayer.addSublayer(dotLayer)
            }
            contentPointArray.append(items)
        }
    }
    
    private func eliminateView(by points: [CGPoint]) -> EliminateView {
        var minPoint: CGPoint = points.first ?? CGPoint.zero
        var maxPoint: CGPoint = CGPoint.zero
        
        for point in points {
            let col = point.y;
            let row = point.x;
            minPoint.x = min(minPoint.x, row)
            minPoint.y = min(minPoint.y, col)
            maxPoint.x = max(maxPoint.x, row)
            maxPoint.y = max(maxPoint.y, col)
        }
        
        let posX = minPoint.x * itemSpacing + originPoint.x
        let posY = minPoint.y * itemSpacing + originPoint.y
        let width = (maxPoint.x - minPoint.x) * itemSpacing
        let height = (maxPoint.y - minPoint.y) * itemSpacing
        let frame = CGRect.init(x: posX, y: posY, width: width, height: height)

        // UIBezierPath
        var originalPoints: Array<CGPoint> = []
        let bezierPath: UIBezierPath = defaultBezierPath()
        
        for (index, pointValue) in points.enumerated() {
            let pointX = (pointValue.x - minPoint.x) * itemSpacing
            let pointY = (pointValue.y - minPoint.y) * itemSpacing
            let realPoint = CGPoint.init(x: pointX, y: pointY)
            originalPoints.append(realPoint)
            
            if 0 == index {
                bezierPath.move(to: realPoint)
            } else {
                bezierPath.addLine(to: realPoint)
            }
        }
        
        bezierPath.close()
        
        let itemView = EliminateView.init(frame: frame)
        itemView.originalPointsArray = originalPoints
        itemView.delegate = self
        itemView.itemWH = itemSpacing
        itemView.firstPoint = originPoint
        itemView.limitArea = self.bounds
        self.addSubview(itemView)
        itemView.addShapeMask(shapePath: bezierPath)
        
        return itemView
    }

    private func defaultBezierPath() -> UIBezierPath {
        let bezierPath = UIBezierPath()
        bezierPath.lineWidth = 0.0
        bezierPath.usesEvenOddFillRule = true
        return bezierPath
    }
    
    private func updateShapeLayer() {
        guard let subViews = items else { return  }
        
        let bezierPath = defaultBezierPath()
        for item in subViews {
            bezierPath.append(item.getCurrentPath(originPoints: item.originalPointsArray))
        }
        bezierPath.usesEvenOddFillRule = true
        bezierPath.stroke()
        bezierPath.fill()
        
        bottomShapLayer.path = bezierPath.cgPath
        bottomShapLayer.fillRule = .evenOdd
    }

    // MARK: public
    public func startGame(from data: LevelModel, isDest: Bool) {
        levelModel = data
        for item in items {
            item.removeFromSuperview()
        }
        items.removeAll()
        
        if isDest {
            if let drawPoints = data.destPoints?.first {
                for packPoints in drawPoints {
                    let item = self.eliminateView(by: packPoints)
                    items.append(item)
                }
            }
            
            updateShapeLayer()
            return
        }
        
        if let drawPoints = data.srcPoints {
            for packPoints in drawPoints {
                let item = self.eliminateView(by: packPoints)
                items.append(item)
            }
            
            updateShapeLayer()
        }

    }
    
    func eliminateViewWillStartMove(_:EliminateView) {
        updateShapeLayer()
    }
    func eliminateViewMoving(_:EliminateView) {
        updateShapeLayer()
    }
    func eliminateViewDidEndMove(_:EliminateView) {
        self.touchSoundEffect?.play()
        
        updateShapeLayer()
        // check game over
        
        if gameOver() {
            self.delegate?.gamePlayViewDidCompeteLevel(level: Int8(levelModel?.levelId ?? 0))
        }
    }
    
    func gameOver() -> Bool {
        
        // check
        let gameOverPath = defaultBezierPath()
        
        guard let targetPoints:Array<Array<Array<CGPoint>>> = levelModel?.destPoints else { return false }
        let firstTargetPoints:Array<Array<CGPoint>> = targetPoints.first ?? [[]]
        
        for element in firstTargetPoints {
            if let path = self.appendPath(from: element) {
                gameOverPath.append(path)
            }
        }
        
        let layerPath: UIBezierPath = UIBezierPath.init(cgPath: bottomShapLayer.path!)
        layerPath.lineWidth = 0.0
        layerPath.usesEvenOddFillRule = true
        
        // check Size equal
        // 过关条件dest数组里面的所有排序方式排好==
        if gameOverPath.bounds.size.equalTo(layerPath.bounds.size) {
            let offsetX: CGFloat = gameOverPath.bounds.minX - layerPath.bounds.minX
            let offsetY: CGFloat = gameOverPath.bounds.minY - layerPath.bounds.minY
            
            let transform = CGAffineTransform.init(translationX: offsetX, y: offsetY)
            layerPath.apply(transform)
            
            if let destPoints = levelModel?.destPoints {
                let passPaths = passBezierPaths(from: destPoints)
                
                for passPath in passPaths {
                    if passPath == layerPath {
                        print("-------- level Pass ----------")
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func passBezierPaths(from destPoints:[[[CGPoint]]]) -> [UIBezierPath] {
        var resultPaths:[UIBezierPath] = []
        
        for pointsArray in destPoints {

            // 遍历所有排列可能性，[1, 2, 3], [2,3,1], [3,2,1], [3,1,2], [1,3,2]
            let sortCount: Int = pointsArray.count
            let allSortedIndexs = sortIndexList(by: UInt(sortCount))
            
            for sortedIndex in allSortedIndexs {
                print(sortedIndex)
                
                let passPath = defaultBezierPath()
                for eleIndex in sortedIndex {
                    if let path = self.appendPath(from: pointsArray[eleIndex]) {
                        passPath.append(path)
                    }
                }
                
                resultPaths.append(passPath)
            }
        }
        
       return resultPaths
    }

    
    /// 指定长度的数组共有多少种排列方式
    /// - Parameter count: 数组长度
    /// - Returns: 所有排列方式的索引
    private func sortIndexList(by count:UInt) -> [[Int]] {
        if count == 0 {
            return [[]]
        }
        
        var indexList:[Int] = []
        for index in 0..<count {
            indexList.append(Int(index))
        }
        
        return permute(indexList)
    }
    
    private func permute (_ arr:[Int]) -> [[Int]] {

        var array = arr
        var result = [[Int]]()
        helper(&array,0,&result)
        return result
    }

    func helper (_ arr: inout [Int], _ begin:Int, _ results: inout [[Int]]){
        
        if begin >= arr.count{
            results.append(arr)
            return
        } else {
            for i in begin..<arr.count{
                // choose
                arr.swapAt(begin, i)
                // explore
                helper(&arr, begin + 1, &results)
                // unchoose
                arr.swapAt(begin, i)
            }
        }
    }
    
    
    func appendPath(from points: [CGPoint]?) -> UIBezierPath? {
        guard let parmPoints: Array<CGPoint> = points else { return nil }
        
        let bezierPath: UIBezierPath = defaultBezierPath()
        
        for (index, element) in parmPoints.enumerated() {
            let x = element.x * itemSpacing + originPoint.x
            let y = element.y * itemSpacing + originPoint.y
            let realPoint = CGPoint.init(x: x, y: y)
            
            if (0 == index) {
                bezierPath.move(to: realPoint)
            } else {
                bezierPath.addLine(to: realPoint)
            }
        }
        bezierPath.close()
        return bezierPath
    }

    
    
    
    func sortTargetPath(targetPoints: [Any]?) -> Array<Any>? {
        guard let pointsList: Array<Any> = targetPoints else { return nil }
        let count = pointsList.count
        if count == 1 {
            return pointsList
        }
        
        var resultList: Array<Any> = []
        for index in 0..<count {
            let element = pointsList[index]
            var deletedArray: Array<Any> = pointsList
                        
            deletedArray.removeAll { (obj) -> Bool in
                if element as AnyObject === obj as AnyObject {
                    return true
                }
                return false
            }
            
            let arrOfSub: Array<Any> = sortTargetPath(targetPoints: deletedArray) ?? []
            for j in 0..<arrOfSub.count {
                var list: Array<Any> = []
                let lastObj = arrOfSub[j]
                
                if lastObj is Array<Any> {
                    let lastArray = lastObj as! Array<Any>
                    if lastArray.first is Array<Any> {
                        list = lastObj as! Array<Any>
                    } else {
                        list = [ lastObj ]
                    }
                } else {
                    list = [ lastObj ]
                }
                
                list.insert(element, at: 0)
                resultList.append(list)
            }
        }
        return resultList
    }
    
}

extension CGPoint {
    func offset(offsetX:CGFloat, offsetY:CGFloat) -> CGPoint {
        return CGPoint.init(x: x + offsetX, y: y + offsetY)
    }
}
