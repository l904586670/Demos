//
//  NSObject+PixelMatrix_Transfer.m
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/28.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import "PixelMatrix+Transfer.h"

@implementation PixelMatrix (Transfer)

- (PixelMatrix *)transferLeft {
    PixelMatrix *leftMatrix = [[PixelMatrix alloc] initWithRow:self.col col:self.row];
    for (int i = 0; i < self.row; i++) {
        for (int j = 0; j < self.col; j++) {
            PixelModel *model = [self valueAtRow:i col:j];
            [leftMatrix setValue:model row:(leftMatrix.row - j - 1) col:i];
        }
    }
    return leftMatrix;
}

- (PixelMatrix *)transferRight {
    PixelMatrix *rightMatrix = [[PixelMatrix alloc] initWithRow:self.col col:self.row];
    for (int i = 0; i < self.row; i++) {
        for (int j = 0; j < self.col; j++) {
            PixelModel *model = [self valueAtRow:i col:j];
            [rightMatrix setValue:model row:j col:(rightMatrix.col - i) - 1];
        }
    }
    return rightMatrix;
}

- (PixelMatrix *)transferDown {
    
    return [[PixelMatrix alloc] init];
}

@end
