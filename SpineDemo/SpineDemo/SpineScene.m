//
//  SpineScene.m
//  SpineDemo
//
//  Created by Rock on 2019/9/2.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import "SpineScene.h"

#import "SpineImport.h"
#import "SGG_SpineBoneAction.h"

@implementation SpineScene {
  SGG_Spine * _boy;
  SKLabelNode *_jumpNode;
  SKLabelNode *_changeNode;
  BOOL _gender;
}

- (instancetype)initWithSize:(CGSize)size {
  self = [super initWithSize:size];
  if (self) {

    [self configuratSpine];
  }
  return self;
}

#pragma mark - Spine

- (void)configuratSpine {
  _boy = [SGG_Spine node];
  //    boy.debugMode = YES;
  //    boy.timeResolution = 1.0 / 1200.0; // this is typically overkill, 1/120 will normally be MORE than enough, but this demo can go to some VERY slow motion. 1/120 is also the default.
  [_boy skeletonFromFileNamed:@"goblins" andAtlasNamed:@"goblin" andUseSkinNamed:@"goblin"];
  _boy.position = CGPointMake(self.size.width/2, self.size.height/4);
  //    [boy runAnimationSequence:@[@"walk", @"jump", @"walk", @"walk", @"jump"] andUseQueue:NO]; //uncomment to see how a sequence works (commment the other animation calls)
  _boy.queuedAnimation = @"walk";
  _boy.name = @"boy";
  _boy.queueIntro = 0.1;
  [_boy runAnimation:@"walk" andCount:0 withIntroPeriodOf:0.1 andUseQueue:YES];
  _boy.zPosition = 0;
  [self addChild:_boy];

  SKLabelNode *actionNode = [SKLabelNode labelNodeWithFontNamed:@"Helvetica Neue Light"];
  actionNode.text = @"jump";
  actionNode.color = [SKColor whiteColor];
  actionNode.position = CGPointMake(self.size.width/2, self.size.height/4 - 40);
  [self addChild:actionNode];

  SKLabelNode *changeNode = [SKLabelNode labelNodeWithFontNamed:@"Helvetica Neue Light"];
  changeNode.text = @"change cloths";
  changeNode.color = [SKColor whiteColor];
  changeNode.position = CGPointMake(self.size.width/2, self.size.height/4 - 70);
  [self addChild:changeNode];

  _jumpNode = actionNode;
  _changeNode = changeNode;
  _gender = NO;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//  CGPoint location = [[touches anyObject] locationInNode:self];
//  [self inputBegan:location];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//  CGPoint location = [[touches anyObject] locationInNode:self];
//  [self inputMoved:location];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  CGPoint location = [[touches anyObject] locationInNode:self];
//  [self inputEnded:location];
  if ([_jumpNode containsPoint:location]) {
    [_boy runAnimation:@"jump" andCount:0 withIntroPeriodOf:0.1 andUseQueue:YES];
  }
  if ([_changeNode containsPoint:location]) {
    _gender = !_gender;
    NSString *skinName = @"goblin";
    if (_gender) {
      skinName = @"goblingirl";
    }

    [_boy changeSkinTo:skinName];
  }
}

- (void)update:(CFTimeInterval)currentTime {
  /* Called before each frame is rendered */

  [_boy activateAnimations];
}

@end
