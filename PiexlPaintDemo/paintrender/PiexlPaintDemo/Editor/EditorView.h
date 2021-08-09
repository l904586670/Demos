//
//  EditorView.h
//  PiexlPaintDemo
//
//  Created by pointone on 2020/5/26.
//  Copyright © 2020 PointOne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PixelMatrix.h"

typedef void(^onClickCallback)(PixelMatrix* _Nullable matrix, UIColor* _Nullable editColor);
typedef void(^onCleanCallback)(PixelMatrix* _Nullable matrix);

NS_ASSUME_NONNULL_BEGIN

@interface EditorView : UIView

@property(nonatomic, copy)onClickCallback clickCallback;
@property(nonatomic, copy)onCleanCallback cleanCallback;

- (void)cleanView;

- (void)setPaintColor:(UIColor *)color;

- (void)updateBrushColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
