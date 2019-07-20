//
//  ChatDelegate.h
//  helpdesk_sdk
//
//  Created by 赵 蕾 on 16/3/29.
//  Copyright © 2016年 hyphenate. All rights reserved.
// corresponds -> EMChatManagerDelegate

#import <Foundation/Foundation.h>
#import "HDMessage.h"
#import "HDError.h"
@protocol HDChatManagerDelegate<NSObject>
@optional
#pragma mark - Message

/*!
 *  \~chinese
 *  收到消息
 *
 *  @param aMessages  消息列表<HDMessage>
 *
 *  \~english
 *  Delegate method will be invoked when receiving new messages
 *
 *  @param aMessages  Receivecd message list<HDMessage>
 */
- (void)messagesDidReceive:(NSArray *)aMessages;

/*!
 *  \~chinese
 *  收到Cmd消息
 *
 *  @param aCmdMessages  Cmd消息列表<HDMessage>
 *
 *  \~english
 *  Delegate method will be invoked when receiving command messages
 *
 *  @param aCmdMessages  Command message list<HDMessage>
 */
- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages;

/*!
 *  \~chinese
 *  收到消息撤回
 *
 *  @param recallMessageIds  撤回消息列表<NSString>
 *
 *  \~english
 * Delegate method will be invoked when receiving recall for message id list
 *
 *  @param recallMessageIds  Recall message id list<NSString>
 */
- (void)messagesDidRecall:(NSArray *)recallMessageIds;

/*!
 *  \~chinese
 *  消息状态发生变化
 *
 *  @param aMessage  状态发生变化的消息
 *  @param aError    出错信息
 *
 *  \~english
 *  Delegate method will be invoked when message status has changed
 *
 *  @param aMessage  Message whose status has changed
 *  @param aError    Error info
 */
- (void)messageStatusDidChange:(HDMessage *)aMessage
                         error:(HDError *)aError;

/*!
 *  \~chinese
 *  消息附件状态发生改变
 *
 *  @param aMessage  附件状态发生变化的消息
 *  @param aError    错误信息
 *
 *  \~english
 *  Delegate method will be invoked when message attachment status has changed
 *
 *  @param aMessage  Message attachment status has changed
 *  @param aError    Error
 */
- (void)messageAttachmentStatusDidChange:(HDMessage *)aMessage
                                   error:(HDError *)aError;

/**
 待接入排队人数

 @param count 排队第几位
 */
- (void)visitorWaitCount:(int)count;


/**
 坐席输入状态变化

 @param content 内容
 */
- (void)agentInputStateChange:(NSString *)content;


@end
