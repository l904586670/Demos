//
//  HDRobotMenuInfo.h
//  helpdesk_sdk
//
//  Created by 赵 蕾 on 16/5/5.
//  Copyright © 2016年 hyphenate. All rights reserved.
//

#import "HDContent.h"

@interface HDRobotMenuInfo : HDContent
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSMutableArray* items;

-(instancetype) initWithObject:(NSMutableDictionary *)obj;
@end

@interface RobotMenuItem : NSObject 
@property (nonatomic, copy) NSString * identity;
@property (nonatomic, copy) NSString * name;

-(instancetype) initWithObject:(NSMutableDictionary *)obj;
@end
