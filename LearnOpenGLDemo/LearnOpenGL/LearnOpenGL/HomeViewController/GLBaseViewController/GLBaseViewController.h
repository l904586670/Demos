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

@property (nonatomic, assign) BOOL hideGLConfig;

@property (nonatomic, strong) GLKView *glkView;

@property (nonatomic, strong, nullable) EAGLContext *content;

@property (nonatomic, assign, readonly) CGRect contentRect;


/**
 加载顶点shader 和 片段shader

 @param vert 顶点shader 文件path
 @param frag 片段shader path
 @return shaderProgram
 */
- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag;

@end

NS_ASSUME_NONNULL_END
