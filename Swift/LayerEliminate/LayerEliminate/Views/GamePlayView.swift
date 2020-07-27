//
//  GamePlayView.swift
//  LayerEliminate
//
//  Created by Rock on 2020/7/24.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

protocol GamePlayViewDelegate  {
    func gamePlayViewDidCompeteLevel(level:Int8)
}

class GamePlayView: UIView, EliminateViewDelegate {
    
    /// 边界间隙
    var paddingInset: UIEdgeInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
    
    var delegate: GamePlayViewDelegate?
    
    /// 矩阵点
    var matrixCount: Int = 15
    
    var bottomShapLayer: CAShapeLayer!
    
    var pointBgLayer: CALayer!
    
    var itemSpacing: CGFloat = 0.0
    
    var contentPointArray: Array<Any> = []
    
    var originPoint: CGPoint = CGPoint.zero
    
    var items: Array<EliminateView>! = []

    var levelModel: LevelModel?

    

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
        
        for x in 0...matrixCount {
            var items: Array<CGPoint> = []
            for y in 0...matrixCount {
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
    
    
    private func creatEliminateView(points: Array<CGPoint>) -> EliminateView {
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
//        itemView.backgroundColor = UIColor.red
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
    
    
    func sortTargetPath(paths:Array<Any>) -> Array<Any>? {
        guard let pathArray:Array<Any> = paths else { return nil }
        let count = pathArray.count
        
        if count == 1 {
            return pathArray
        }
        var tmp:Array<Any> = []
//        for index in 0...count {
//            var deletedArray = pathArray
//            deletedArray.remove(at: index)
//            
//            let arrOfSub: Array<Any> = sortTargetPath(paths: deletedArray) ?? []
//            
//            for item in arrOfSub {
//                var lastArray:Array<Any> = []
//                if (item as AnyObject).isKindOfClass(Array) {
//                    lastArray = item
//                } else {
//                    lastArray.append(item)
//                }
//            }
//        }
        
        return nil
    }

    // MARK: public

    func startGameFromData(model: LevelModel!) {
        guard let levelItem:LevelModel = model else { return  }
        levelModel = levelItem

        for item in items {
            item.removeFromSuperview()
        }
        items?.removeAll()

        guard let drawPoints = levelItem.srcPoints else { return  }

        for packPoints in drawPoints {
            let item = creatEliminateView(points: packPoints)
            items.append(item)
        }
//        updateShapeLayer()
    }
    
    func eliminateViewWillStartMove(_:EliminateView) {
        updateShapeLayer()
    }
    func eliminateViewMoving(_:EliminateView) {
        updateShapeLayer()
    }
    func eliminateViewDidEndMove(_:EliminateView) {
        updateShapeLayer()
        // check game over
    }
}

extension CGPoint {
    func offset(offsetX:CGFloat, offsetY:CGFloat) -> CGPoint {
        return CGPoint.init(x: x + offsetX, y: y + offsetY)
    }
}
