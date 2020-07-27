//
//  EliminateView.swift
//  LayerEliminate
//
//  Created by Rock on 2020/7/23.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

import AVFoundation

protocol EliminateViewDelegate  {
  func eliminateViewWillStartMove(_:EliminateView)
  func eliminateViewMoving(_:EliminateView)
  func eliminateViewDidEndMove(_:EliminateView)
}

class EliminateView: UIView {
    var delegate: EliminateViewDelegate?
    var limitArea: CGRect?
    var itemWH: CGFloat = 0.0
    var firstPoint: CGPoint = CGPoint.zero
    var currentPath: UIBezierPath?
    var maskPath: UIBezierPath?
    var moveStartPoint: CGPoint = CGPoint.zero
    var moveCenterPoint: CGPoint = CGPoint.zero
    
    var originalPointsArray: Array<CGPoint>?
    
    
    //MARK: override
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addPanRecognizer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        addPanRecognizer()
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let path = maskPath else { return true }
        if path.contains(point) {
            return true
        }
        return false
    }
    
    // MARK: public
    public func addShapeMask(shapePath:UIBezierPath!) {
        guard let path = shapePath else {
            self.layer.mask = nil
            return
        }
        maskPath = path
        let maskLayer = CAShapeLayer.init();
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
    
    public func getCurrentPath(originPoints: Array<CGPoint>!) -> UIBezierPath {
        let bezierPath = UIBezierPath()
        
        for (index, pointValue) in originPoints.enumerated() {
            let pointX = pointValue.x + self.frame.minX
            let pointY = pointValue.y + self.frame.minY
            let realPoint = CGPoint.init(x: pointX, y: pointY)
            if 0 == index {
                bezierPath.move(to: realPoint)
            } else {
                bezierPath.addLine(to: realPoint)
            }
        }
        bezierPath.close()
        
        return bezierPath
    }
    
    func updatePointsArray(originPoints: Array<CGPoint>!) -> Array<CGPoint> {
        var points:[CGPoint] = []
        for pointValue in originPoints {
            let pointX = pointValue.x + self.frame.minX
            let pointY = pointValue.y + self.frame.minY
            let realPoint = CGPoint.init(x: pointX, y: pointY)
            
            points.append(realPoint)
        }
    
        return points
    }
    
    // MARK: private
    
    private func addPanRecognizer() {
        let methodB = #selector(onPan as (UIPanGestureRecognizer) -> ())
        let pan = UIPanGestureRecognizer.init(target: self, action: methodB)
        self.addGestureRecognizer(pan)
    }
    
    @objc func onPan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            recognizer.setTranslation(CGPoint.init(x: 0, y: 0), in: self)
            moveStartPoint = recognizer.translation(in: self)
            self.moveCenterPoint = self.center
            
            self.delegate?.eliminateViewWillStartMove(self)
        } else if (recognizer.state == .changed) {
            let point = recognizer.translation(in: self)
            let dx = point.x - moveStartPoint.x
            let dy = point.y - moveStartPoint.y
            print("dx : \(dx) dy : \(dy)")
            let newCenter = CGPoint.init(x: self.center.x + dx, y: self.center.y + dy)
            self.center = newCenter
            
            recognizer.setTranslation(CGPoint.init(x: 0, y: 0), in: self)
            self.delegate?.eliminateViewMoving(self)
        } else if (recognizer.state == .ended) {
            
            let outside = limitArea?.contains(self.frame)
            if outside == false {
                UIView.animate(withDuration: 0.3, animations: {
                    self.center = self.moveCenterPoint
                    self.delegate?.eliminateViewMoving(self)
                }) { (finished) in
                    self.delegate?.eliminateViewDidEndMove(self)
                }
            } else {
                let viewPosX = self.frame.minX
                let viewPosY = self.frame.minY
                var itemIndexX: Int = Int((viewPosX - firstPoint.x)/itemWH)
                let wSpacing = viewPosX - firstPoint.x - (CGFloat(itemIndexX) * itemWH)
                if wSpacing > itemWH/2.0 {
                    itemIndexX += 1
                }

                var itemIndexY: Int = Int((viewPosY - firstPoint.y) / itemWH)
                let hSpacing = viewPosY - firstPoint.y - (CGFloat(itemIndexY) * itemWH)
                if (hSpacing > itemWH/2.0) {
                    itemIndexY += 1
                }
                let frame = CGRect.init(x: CGFloat(itemIndexX) * itemWH + firstPoint.x, y: CGFloat(itemIndexY) * itemWH + firstPoint.y, width: self.frame.width, height: self.frame.height)
                print("move frame : \(frame)")
                self.frame = frame

                self.delegate?.eliminateViewDidEndMove(self)

                recognizer.setTranslation(CGPoint.zero, in: self)
            }
        }
    }
    
    private func defaultBezierPath() -> UIBezierPath {
        let bezierPath = UIBezierPath()
        bezierPath.lineWidth = 0.0
        bezierPath.usesEvenOddFillRule = true
        return bezierPath
    }
    
}
