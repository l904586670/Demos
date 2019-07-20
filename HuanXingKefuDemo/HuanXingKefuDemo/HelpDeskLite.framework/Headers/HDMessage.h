//
//  HDMessage.h
//  helpdesk_sdk
//
//  Created by 赵 蕾 on 16/3/29.
//  Copyright © 2016年 hyphenate. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDContent.h"
#import "HDCompositeContent.h"
#import "HDVisitorInfo.h"
#import "HDVisitorTrack.h"
#import "HDOrderInfo.h"
#import "HDAgentInfo.h"
#import "HDAgentIdentityInfo.h"
#import "HDQueueIdentityInfo.h"
#import "HDRobotMenuInfo.h"
#import "HDTransferIndication.h"
#import "HDControlMessage.h"
#import <UIKit/UIKit.h>

#import <HyphenateLite/HyphenateLite.h>

/*!
 *  \~chinese
 *  消息发送状态
 *
 *  \~english
 *   Message Status
 */
typedef enum{
    HDMessageStatusPending  = 0,    /*! \~chinese 发送未开始 \~english Pending */
    HDMessageStatusDelivering,      /*! \~chinese 正在发送 \~english Delivering */
    HDMessageStatusSuccessed,       /*! \~chinese 发送成功 \~english Successed */
    HDMessageStatusFailed,          /*! \~chinese 发送失败 \~english Failed */
}HDMessageStatus;

/*!
 *  \~chinese
 *  消息方向
 *
 *  \~english
 *  Message direction
 */
typedef enum{
    HDMessageDirectionSend = 0,    /*! \~chinese 发送的消息 \~english Send */
    HDMessageDirectionReceive,     /*! \~chinese 接收的消息 \~english Receive */
}HDMessageDirection;

@interface HDMessage : NSObject
/*!
 *  \~chinese
 *  消息的唯一标识符
 *
 *  \~english
 *  Unique identifier of message
 */
@property (nonatomic, copy) NSString *messageId;

@property (nonatomic) long long timestamp __attribute__((deprecated("已过期, 请使用messageTime")));

/*!
 *  \~chinese
 *  时间戳，服务器收到此消息的时间
 *
 *  \~english
 *  messageTime, the time of server received this message
 */
@property (nonatomic) long long messageTime;

/*!
 *  \~chinese
 *  客户端发送/收到此消息的时间
 *
 *  \~english
 *  The time of client send/receive the message
 */
@property (nonatomic) long long localTime __attribute__((deprecated("已过期, 请使用messageTime")));;
/*!
 *  \~chinese
 *  消息的方向
 *
 *  \~english
 *  Message direction
 */
@property (nonatomic) HDMessageDirection direction;

/*!
 *  \~chinese
 *  所属会话的唯一标识符
 *
 *  \~english
 *  Unique identifier of message's conversation
 */
@property (nonatomic, copy) NSString *conversationId;

/*!
 *  \~chinese
 *  发送方
 *
 *  \~english
 *  The sender
 */
@property (nonatomic, copy) NSString *from;

/*!
 *  \~chinese
 *  接收方
 *
 *  \~english
 *  The receiver
 */
@property (nonatomic, copy) NSString *to;

/*!
 *  \~chinese
 *  消息状态
 *
 *  \~english
 *  Message status
 */
@property (nonatomic)HDMessageStatus status;

/*!
 *  \~chinese
 *  消息体
 *
 *  \~english
 *  Message body
 */
@property (nonatomic, strong) EMMessageBody *body;

/*!
 *  \~chinese
 *  消息扩展
 *
 *  Key值类型必须是NSString, Value值类型必须是NSString或者 NSNumber类型的 BOOL, int, unsigned in, long long, double.
 *
 *  \~english
 *  Message extention
 *
 *  Key type must be NSString, Value type must be NSString or NSNumber of BOOL, int, unsigned in, long long, double.
 */
@property (nonatomic, copy) NSDictionary *ext;

/*!
 *  \~chinese
 *  初始化消息实例
 *
 *  @param aConversationId  会话ID
 *  @param aFrom            发送方
 *  @param aTo              接收方
 *  @param aBody            消息体实例
 *  @param aExt             扩展信息
 *
 *  @result 消息实例
 *
 *  \~english
 *  Initialize a message instance
 *
 *  @param aConversationId  Conversation id
 *  @param aFrom            The sender
 *  @param aTo              The receiver
 *  @param aBody            Message body
 *  @param aExt             Message extention
 *
 *  @result Message instance
 */
- (id)initWithConversationID:(NSString *)aConversationId
                        from:(NSString *)aFrom
                          to:(NSString *)aTo
                        body:(EMMessageBody *)aBody;

- (void)addAttributeDictionary:(NSDictionary *)dic;

/**
 create Txt message

 @param content
 @param toUserName
 @return HDMessage
 */
+(instancetype)createTxtSendMessageWithContent:(NSString *)content
                                            to:(NSString *)toUserName;


/**
 create image message

 @param imageData
 @param imageName
 @param toUserName
 @return HDMessage
 */
+(instancetype)createImageSendMessageWithData:(NSData *) imageData displayName:(NSString *) imageName to:(NSString *) toUserName;


/**
 create image message use image

 @param image
 @param toUserName
 @return HDMessage
 */
+(instancetype)createImageSendMessageWithImage:(UIImage *) image to:(NSString *) toUserName __attribute__((deprecated("已过期, 请使用createImageSendMessageWithImage:displayName:to:")));

/**
 create image message use image
 
 @param image
 @param imageName
 @param toUserName
 @return HDMessage
 */
+(instancetype)createImageSendMessageWithImage:(UIImage *)image
                                   displayName:(NSString *)imageName
                                            to:(NSString *) toUserName;


/**
 create voice send message

 @param localPath
 @param duration
 @param toUserName
 @return HDMessage
 */
+(instancetype)createVoiceSendMessageWithLocalPath:(NSString *)localPath
                                          duration:(int)duration
                                                to:(NSString *)toUserName;

/**
 create video send message
 
 @param localPath
 @param toUsername
 
 @return HDMessage
 */

+ (instancetype)createVideoSendMessageWithLocalPath:(NSString *)aLocalPath
                                                 to:(NSString *)toUsername;

/**
 create bigExpression send message

 @param url emoji url
 @param toUserName toUsername
 @return HDMessage
 */
+ (instancetype)createBigExpressionSendMessageWithUrl:(NSString *)url
                                                   to:(NSString *)toUserName;


/**
 create location send message

 @param latitude
 @param longitude
 @param address
 @param toUserName
 @return HDMessage
 */
+(instancetype)createLocationSendMessageWithLatitude:(double)latitude
                                           longitude:(double)longitude
                                             address:(NSString *)address
                                                  to:(NSString *)toUserName;


/**
 create file send message

 @param localPath
 @param toUserName
 @return HDMessage
 */
+(instancetype)createFileSendMessageWithLocalPath:(NSString *)localPath
                                               to:(NSString *)toUserName;


/**
 create file send message

 @param localPath
 @param displayName
 @param toUserName
 @return HDMessage
 */
+(instancetype)createFileSendMessageWithLocalPath:(NSString *)localPath
                                      displayName:(NSString *)displayName
                                               to:(NSString *)toUserName;


/**
 create video send message
 
 @param localPath
 @param displayName
 @param toUserName
 @return HDMessage
 */
+ (instancetype)createVideoSendMessageWithLocalPath:(NSString *)aLocalPath
                                        displayName:(NSString *)aDisplayName
                                                 to:(NSString *)toUsernam                                        ;

/**
 check voice message if it is listened

 @return YES or NO
 */
- (BOOL) isListened;


/**
 set voice message is listened

 @param isListened the voice file was played.
 */
- (void)setListened:(BOOL)isListened;

@end

