//
//  NSObject+Unitily.h
//  WebJsDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Unitily)

/**
 发送消息

 @param selector 要被调用的方法名
 @param returnValue 返回值的指针地址
 @param firstArgument 参数
 */
- (void)dh_performSelector:(SEL)selector
           withReturnValue:(void *)returnValue
                 arguments:(void *)firstArgument, ... ;

/**
 使用 block 遍历指定 class 的所有成员变量（也即 _xxx 那种），不包含 property 对应的 _property 成员变量，也不包含 superclasses 里定义的变量
 
 @param block 用于遍历的 block
 */
- (void)dh_enumrateIvarsUsingBlock:(void (^)(Ivar ivar, NSString *ivarName))block;

/**
 使用 block 遍历指定 class 的所有成员变量（也即 _xxx 那种），不包含 property 对应的 _property 成员变量
 
 @param aClass 指定的 class
 @param includingInherited 是否要包含由继承链带过来的 ivars
 @param block  用于遍历的 block
 */
+ (void)dh_enumrateIvarsOfClass:(Class)aClass
             includingInherited:(BOOL)includingInherited
                     usingBlock:(void (^)(Ivar, NSString *))block;

@end

NS_ASSUME_NONNULL_END
