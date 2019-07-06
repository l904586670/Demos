//
//  GLBaseViewController.h
//  LearnOpenGL
//
//  Created by User on 2019/7/6.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <GLKit/GLKit.h>
#import <OpenGLES/ES3/gl.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLBaseViewController : GLKViewController <GLKViewControllerDelegate>

@property (nonatomic, strong) GLKView *glkView;

@property (nonatomic, strong) EAGLContext *content;

@end

NS_ASSUME_NONNULL_END
