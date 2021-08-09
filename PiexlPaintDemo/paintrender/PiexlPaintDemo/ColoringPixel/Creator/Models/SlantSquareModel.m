//
//  SlantSquareModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/25.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "SlantSquareModel.h"

@implementation SlantSquareModel
- (instancetype)init {
    if (self = [super init]) {
        self.direct = SquareDirectUndefined;
        self.type = SquareTypeUndefined;
        self.positionX = 0;
        self.positionY = 0;
        self.width = 0;
        self.height = 0;
    }
    return self;
}
@end
