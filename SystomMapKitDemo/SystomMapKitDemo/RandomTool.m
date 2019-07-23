//
//  RandomTool.m
//  SystomMapKitDemo
//
//  Created by User on 2019/7/23.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "RandomTool.h"

#import <GameplayKit/GameplayKit.h>

@implementation RandomTool

+ (NSInteger)randomInteger:(NSInteger)max {
  return [self randomIntegerWithMin:0 max:max];
}

+ (NSInteger)randomIntegerWithMin:(NSInteger)min max:(NSInteger)max {
  GKRandomSource *randomSource = [GKARC4RandomSource sharedRandom];
  GKRandomDistribution *distribution = [[GKRandomDistribution alloc] initWithRandomSource:randomSource
                                                                              lowestValue:min
                                                                             highestValue:(max-1)];
  return [distribution nextInt];
}

+ (float)randomFloat {
  return [[GKARC4RandomSource sharedRandom] nextUniform];
}

+ (float)randomFloat:(float)max {
  return [[self class] randomFloatWithMin:0.0 max:max];
}

+ (float)randomFloatWithMin:(float)min max:(float)max {
  CGFloat uniform = [[self class] randomFloat];
  return (min + (max - min) * uniform);
}

+ (BOOL)randomRatio:(float)ratio {
  return [[self class] randomFloat] < ratio;
}

@end
