//
//  NSObject+Unitily.m
//  WebJsDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "NSObject+Unitily.h"

@implementation NSObject (Unitily)

- (void)dh_PerformSelector:(SEL)selector withReturnValue:(void *)returnValue arguments:(void *)firstArgument, ... {
  
  NSMethodSignature *signature = [self methodSignatureForSelector:selector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:self];
  [invocation setSelector:selector];
  
  if (firstArgument) {
    [invocation setArgument:firstArgument atIndex:2];
    
    va_list args;
    va_start(args, firstArgument);
    void *currentArgument;
    NSInteger index = 3;
    while ((currentArgument = va_arg(args, void *))) {
      [invocation setArgument:currentArgument atIndex:index];
      index++;
    }
    va_end(args);
  }
  
  [invocation invoke];
  
  if (returnValue) {
    [invocation getReturnValue:returnValue];
  }
}

- (void)dh_enumrateIvarsUsingBlock:(void (^)(Ivar ivar, NSString *ivarName))block {
  [NSObject dh_enumrateIvarsOfClass:self.class
                 includingInherited:NO
                         usingBlock:block];
}


+ (void)dh_enumrateIvarsOfClass:(Class)aClass includingInherited:(BOOL)includingInherited usingBlock:(void (^)(Ivar, NSString *))block {
  unsigned int outCount = 0;
  Ivar *ivars = class_copyIvarList(aClass, &outCount);
  for (unsigned int i = 0; i < outCount; i ++) {
    Ivar ivar = ivars[i];
    if (block) block(ivar, [NSString stringWithFormat:@"%s", ivar_getName(ivar)]);
  }
  free(ivars);
  
  if (includingInherited) {
    Class superclass = class_getSuperclass(aClass);
    if (superclass) {
      [NSObject dh_enumrateIvarsOfClass:superclass includingInherited:includingInherited usingBlock:block];
    }
  }
}

@end
