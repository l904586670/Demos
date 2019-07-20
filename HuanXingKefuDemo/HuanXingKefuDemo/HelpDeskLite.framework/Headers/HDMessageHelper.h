//
//  HDMessageHelper.h
//  helpdesk_sdk
//
//  Created by liyuzhao on 14/09/2017.
//  Copyright © 2017 hyphenate. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    HDExtGeneralMsg,  // 默认选项，一般为正常的文本消息
    HDExtEvaluationMsg, // 满意度评价消息
    HDExtOrderMsg, // 订单消息
    HDExtTrackMsg, // 轨迹消息
    HDExtFormMsg, // 表单消息
    HDExtRobotMenuMsg, // 机器人菜单消息
    HDExtArticleMsg, // 图文混排消息
    HDExtToCustomServiceMsg, // 转人工客服消息
    HDExtBigExpressionMsg // 大表情消息
}HDExtMsgType;



@interface HDMessageHelper : NSObject

+ (HDExtMsgType)getMessageExtType:(HDMessage *)message; // 检测是哪种消息类型
+ (BOOL)isTrackMessage:(HDMessage *)message;     //轨迹消息
+ (BOOL)isOrderMessage:(HDMessage *)message;     //订单消息
+ (BOOL)isMenuMessage:(HDMessage *)message;      //菜单消息
+ (BOOL)isToCustomServiceMessage:(HDMessage *)message;  //转人工客服消息
+ (BOOL)isEvaluationMessage:(HDMessage *)message;  //满意度评价消息
+ (BOOL)isFormMessage:(HDMessage *)message; //机器人表单消息
+ (BOOL)isBigExpressionMessage:(HDMessage *)message; //大表情消息




@end
