//
//  Person.h
//  ObjDemo
//
//  Created by Rock on 2019/3/12.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PersonModel;

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject <NSCopying>

@property(nonatomic, assign) NSInteger index;

@property(nonatomic, strong) NSString *name;

@property(nonatomic, assign) NSInteger age;

@property(nonatomic, strong) NSString *gender;


- (instancetype)initWithModel:(PersonModel *)model;


@end

NS_ASSUME_NONNULL_END
