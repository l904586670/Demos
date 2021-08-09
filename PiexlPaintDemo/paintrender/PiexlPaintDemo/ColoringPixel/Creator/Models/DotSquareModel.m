//
//  DotSquareModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/29.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "DotSquareModel.h"

@implementation DotSquareModel

- (instancetype)init {
    if (self = [super init]) {
        self.type = SquareTypeDotSquare;
        self.width = 1;
        self.height = 1;
    }
    return self;
}

@end
