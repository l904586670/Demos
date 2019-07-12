//
//  TransformGLView.h
//  LearnOpenGL
//
//  Created by User on 2019/7/8.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TransformGLView : UIView

@property (nonatomic, assign) BOOL bX;
@property (nonatomic, assign) BOOL bY;

- (void)start;

- (void)end;

@end

NS_ASSUME_NONNULL_END
