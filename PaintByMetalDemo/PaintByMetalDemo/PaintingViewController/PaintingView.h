//
//  PaintingView.h
//  PaintByMetalDemo
//
//  Created by User on 2019/7/24.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PaintingView : UIView

@property (nonatomic, assign) CGPoint location;
@property (nonatomic, assign) CGPoint previousLocation;

- (void)erase;
- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;

- (void)paint;
- (void)clearPaint;

@end

NS_ASSUME_NONNULL_END
