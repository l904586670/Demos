//
//  SphereRenderView.h
//  SphereRefractionDemo
//
//  Created by User on 2019/8/7.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SphereRenderView : UIView

// 0.0001
@property (nonatomic, assign) float radius;
// default 0.71
@property (nonatomic, assign) float refractiveIndex;

// [0, 1].
@property (nonatomic, assign) CGPoint centerP;

// 
//@property (nonatomic, assign) CGPoint center;

@end

NS_ASSUME_NONNULL_END
