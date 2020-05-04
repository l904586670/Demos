//
//  PersonModel.h
//  ObjDemo
//
//  Created by Rock on 2019/3/12.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PersonModel : NSObject

@property(nonatomic, assign) NSInteger age;

@property(nonatomic, strong) NSString *name;

@property(nonatomic, strong) NSString *gender;


+ (PersonModel *)randomModel;

@end

NS_ASSUME_NONNULL_END
