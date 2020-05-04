//
//  Person.m
//  ObjDemo
//
//  Created by Rock on 2019/3/12.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import "Person.h"

#import "PersonModel.h"

@implementation Person {
  PersonModel *_model;
}

- (instancetype)initWithModel:(PersonModel *)model {
  self = [super init];
  if (self) {
    _model = model;
  }
  return self;
}

- (NSString *)name {
  return _model.name;
}

- (NSInteger)age {
  return _model.age;
}

- (NSString *)gender {
  return _model.gender;
}

- (id)copyWithZone:(nullable NSZone *)zone {

  Person *model = [[[self class] allocWithZone:zone] init];
  model.index = self.index;
  model.name  = self.name;
  model.age = self.age;
  model.gender = self.gender;

  //未公开的成员
  model->_model = _model;

  return model;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return [self isEqualToPerson:(Person *)object];
}

- (BOOL)isEqualToPerson:(Person *)person {
  if (!person) {
    return NO;
  }

  BOOL haveEqualNames = (!self.name && !person.name) || [self.name isEqualToString:person.name];
  BOOL haveEqualBirthdays = (!self.age && !person.age) || (self.age == person.age);
  BOOL haveEqualGender = (!self.gender && !person.gender) || [self.gender isEqualToString:person.gender];

  return haveEqualNames && haveEqualBirthdays && haveEqualGender;
}

@end
