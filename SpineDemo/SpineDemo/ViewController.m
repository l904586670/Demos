//
//  ViewController.m
//  SpineDemo
//
//  Created by Rock on 2019/9/2.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import "ViewController.h"

#import <SpriteKit/SpriteKit.h>
#import "SpineScene.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  SKView *skView = [[SKView alloc] initWithFrame:self.view.bounds];
  [self.view addSubview:skView];

  if (!skView.scene) {
    skView.showsFPS = YES;

    self.view.multipleTouchEnabled = NO;

    NSLog(@"scene size: %f %f", skView.bounds.size.width, skView.bounds.size.height);

    // Create and configure the scene.
    SKScene* scene = [SpineScene sceneWithSize:CGSizeMake(320, 586)];

    //    NSLog(@"scene size is %f x %f", skView.bounds.size.width, skView.bounds.size.height);

    scene.scaleMode = SKSceneScaleModeAspectFill;

    // Present the scene.
    [skView presentScene:scene];
  }

}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (BOOL)shouldAutorotate {
  return YES;
}



@end
