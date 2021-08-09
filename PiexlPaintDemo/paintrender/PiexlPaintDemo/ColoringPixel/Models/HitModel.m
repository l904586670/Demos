//
//  HitModel.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/29.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "HitModel.h"

@implementation HitModel

- (instancetype)init {
    if (self = [super init]) {
        self.hitTypeArray = [NSMutableArray array];
        self.isDraw = false;
    }
    return self;
}

@end
