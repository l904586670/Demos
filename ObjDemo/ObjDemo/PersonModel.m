//
//  PersonModel.m
//  ObjDemo
//
//  Created by Rock on 2019/3/12.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import "PersonModel.h"

@implementation PersonModel

+ (PersonModel *)randomModel {
  PersonModel *model = [[PersonModel alloc] init];

  model.age = arc4random() % 10;
  model.name = [NSString stringWithFormat:@"name%@", @(arc4random() % 1000)];
  NSArray *genders = @[@"man", @"woman"];
  NSInteger genderRandomIdx = arc4random() % genders.count;
  model.gender = genders[genderRandomIdx];

  return model;
}

@end
