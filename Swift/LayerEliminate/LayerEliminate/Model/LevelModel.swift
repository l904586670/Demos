//
//  LevelModel.swift
//  LayerEliminate
//
//  Created by Rock on 2020/7/23.
//  Copyright © 2020 Rock. All rights reserved.
//

import UIKit

class LevelModel: NSObject, Codable {
    let levelId: Int
    let srcPoints: Array<Array<CGPoint>>?
    let destPoints: Array<Array<CGPoint>>?

    init(dict:Dictionary<String,Any>) {
        self.levelId = dict["level"] as! Int
        self.srcPoints = convertDataType(data: dict["srcPoints"] as! Array<Array<Any>>)
        self.destPoints = convertDataType(data: dict["destPoints"] as! Array<Array<Any>>)

        super.init()
    }
}

func convertDataType(data:Array<Array<Any>>) -> Array<Array<CGPoint>> {
    var list: Array<Array<CGPoint>> = []
    for arr in data {
        var contentList: Array<CGPoint> = []
        for item in arr {
            if (item is String) {
                var itemStr: String = item as! String

                itemStr.removeLast()
                itemStr.removeFirst()

                let arraySubstrings: [String] = itemStr.components(separatedBy: ",")
                let posX: CGFloat = StringToFloat(str: arraySubstrings[0])
                let posY: CGFloat = StringToFloat(str: arraySubstrings[1])
                contentList.append(CGPoint.init(x: posX, y: posY))
//                print("String")
            } else if (item is CGPoint) {
//                print("CGPoint")
                contentList.append(item as! CGPoint)
            }
        }
        list.append(contentList)
    }
    return list
}

func StringToFloat(str: String) -> (CGFloat) {
    let string = str
    var cgFloat: CGFloat = 0

    if let doubleValue = Double(string) {
        cgFloat = CGFloat(doubleValue)
    }
    return cgFloat
}
