//
//  ViewController.m
//  HuanXingKefuDemo
//
//  Created by User on 2019/7/16.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "HConversationsViewController.h"

static CGFloat kDefaultPlaySoundInterval = 3.0;

@interface ViewController () <HDChatManagerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *listButton;

@property (nonatomic, assign) BOOL isLogining;

@property (nonatomic, strong) NSDate *lastPlaySoundDate;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self registerNotifications];
  
}

#pragma mark - Private Methods

- (void)registerNotifications {
  [self unregisterNotifications];
  
  [[HDClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
}

- (void)unregisterNotifications {
  [[HDClient sharedClient].chatManager removeDelegate:self];
}

- (void)_playSoundAndVibration {
  NSTimeInterval timeInterval = [[NSDate date]
                                 timeIntervalSinceDate:self.lastPlaySoundDate];
  if (timeInterval < kDefaultPlaySoundInterval) {
    //如果距离上次响铃和震动时间太短, 则跳过响铃
    NSLog(@"skip ringing & vibration %@, %@", [NSDate date], self.lastPlaySoundDate);
    return;
  }
  
  //保存最后一次响铃时间
  self.lastPlaySoundDate = [NSDate date];
  
  // 收到消息时，播放音频
  [[HDCDDeviceManager sharedInstance] playNewMessageSound];
  // 收到消息时，震动
  [[HDCDDeviceManager sharedInstance] playVibration];
}

- (void)_showNotificationWithMessage:(NSArray *)messages
{
  HDPushOptions *options = [[HDClient sharedClient] hdPushOptions];
  //发送本地推送
  UILocalNotification *notification = [[UILocalNotification alloc] init];
  notification.fireDate = [NSDate date]; //触发通知的时间
  
  if (options.displayStyle == HDPushDisplayStyleMessageSummary) {
    id<HDIMessageModel> messageModel  = messages.firstObject;
    NSString *messageStr = nil;
    switch (messageModel.body.type) {
      case EMMessageBodyTypeText:
      {
        messageStr = ((EMTextMessageBody *)messageModel.body).text;
      }
        break;
      case EMMessageBodyTypeImage:
      {
        messageStr = NSLocalizedString(@"message.image", @"Image");
      }
        break;
      case EMMessageBodyTypeLocation:
      {
        messageStr = NSLocalizedString(@"message.location", @"Location");
      }
        break;
      case EMMessageBodyTypeVoice:
      {
        messageStr = NSLocalizedString(@"message.voice", @"Voice");
      }
        break;
      case EMMessageBodyTypeVideo:{
        messageStr = NSLocalizedString(@"message.vidio", @"Vidio");
      }
        break;
      default:
        break;
    }
    
    NSString *title = messageModel.from;
    notification.alertBody = [NSString stringWithFormat:@"%@:%@", title, messageStr];
  } else{
    notification.alertBody = NSLocalizedString(@"receiveMessage", @"you have a new message");
  }
  
#warning 去掉注释会显示[本地]开头, 方便在开发中区分是否为本地推送
  //notification.alertBody = [[NSString alloc] initWithFormat:@"[本地]%@", notification.alertBody];
  
  notification.alertAction = NSLocalizedString(@"open", @"Open");
  notification.timeZone = [NSTimeZone defaultTimeZone];
  notification.soundName = UILocalNotificationDefaultSoundName;
  //发送通知
  [[UIApplication sharedApplication] scheduleLocalNotification:notification];
  NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber;
  
  [UIApplication sharedApplication].applicationIconBadgeNumber = ++badge;
}

#pragma mark - HDChatManagerDelegate

// 收到消息回调
- (void)messagesDidReceive:(NSArray *)aMessages {
  if ([self isNotificationMessage:aMessages.firstObject]) {
    return;
  }
#if !TARGET_IPHONE_SIMULATOR
  BOOL isAppActivity = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
  if (!isAppActivity) {
    [self _showNotificationWithMessage:aMessages];
  }else {
    [self _playSoundAndVibration];
  }
#endif

#warning To Do post conversation List Refresh Data Notification
//  [_conversationsVC refreshData];

}


- (BOOL)isNotificationMessage:(HDMessage *)message {
  if (message.ext == nil) { //没有扩展
    return NO;
  }
  NSDictionary *weichat = [message.ext objectForKey:kMesssageExtWeChat];
  if (weichat == nil || weichat.count == 0 ) {
    return NO;
  }
  if ([weichat objectForKey:@"notification"] != nil && ![[weichat objectForKey:@"notification"] isKindOfClass:[NSNull class]]) {
    BOOL isNotification = [[weichat objectForKey:@"notification"] boolValue];
    if (isNotification) {
      return YES;
    }
  }
  return NO;
}


#pragma mark - Button Action

- (IBAction)onProductOneTouch:(id)sender {
  NSDictionary *info = @{@"type":@"track", @"title":NSLocalizedString(@"em_chat_I_focus", @"I focus on"), @"desc":NSLocalizedString(@"em_example1_text", @"Crackie leather bomber"), @"price":@"¥8000", @"img_url":@"http://o8ugkv090.bkt.clouddn.com/hd_one.png", @"item_url":@"http://www.easemob.com"};
  
  [self chatAction:info conversation:@"kefuchannelimid_773529"]; // 106531
}

- (IBAction)onProductTwoTouch:(id)sender {
  NSDictionary *info = @{@"type":@"order", @"title":NSLocalizedString(@"em_chat_I_focus", @"I focus on"), @"order_title":[NSString stringWithFormat:@"%@%d",NSLocalizedString(@"order_number", @"Order number:"),123], @"desc":NSLocalizedString(@"em_example3_text", @"Jeffrey campbell duice pump"), @"price":@"¥5400", @"img_url":@"http://o8ugkv090.bkt.clouddn.com/hd_three.png", @"item_url":@"http://www.lagou.com/"};
  [self chatAction:info conversation:@"kefuchannelimid_269328"]; // 106195
}

- (IBAction)onListbuttonTouch:(id)sender {
  HConversationsViewController *listVC = [[HConversationsViewController alloc] init];
  [self.navigationController pushViewController:listVC animated:YES];
}

#pragma mark - Private Methods

- (void)chatAction:(NSDictionary *)commodityInfo conversation:(NSString *)conversation {
  if (_isLogining) {
    return;
  }
  _isLogining = YES;
  [SVProgressHUD showWithStatus:NSLocalizedString(@"Contacting...", @"连接客服")];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    CSDemoAccountManager *lgM = [CSDemoAccountManager shareLoginManager];
    if ([lgM loginKefuSDK]/*[self loginKefuSDK:shouqian]测试切换账号使用*/ ) {
      //            [[EMClient sharedClient] logout:YES];//测试第二通道
//      [self setPushOptions];;
      
      HDChatViewController *chat = [[HDChatViewController alloc] initWithConversationChatter:conversation];

      chat.visitorInfo   = [self visitorInfo];
      chat.commodityInfo = commodityInfo;
   
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
        [self.navigationController pushViewController:chat animated:YES];
      });
      
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"loginFail", @"login fail")];
        [SVProgressHUD dismissWithDelay:1.0];
      });
      NSLog(@"登录失败");
    }
  });
  
  _isLogining = NO;
}

- (void)setPushOptions {
  if ([[CSDemoAccountManager shareLoginManager] loginKefuSDK]) {
    HDPushOptions *HDOptions = [[HDClient sharedClient] getPushOptionsFromServerWithError:nil];
    HDOptions.displayStyle = HDPushDisplayStyleMessageSummary;
    HDError *error =  [[HDClient sharedClient] updatePushOptionsToServer:HDOptions];
    NSLog(@" error:%@",error.errorDescription);
  }
}


- (HDVisitorInfo *)visitorInfo {
  HDVisitorInfo *visitor = [[HDVisitorInfo alloc] init];
  visitor.name = @"小明";
  visitor.qq =   @"ios";
  visitor.phone = @"13636362637";
  visitor.companyName = @"魔迦";
  visitor.nickName = [CSDemoAccountManager shareLoginManager].nickname;
  visitor.email = @"abv@126.com";
  visitor.desc =  @"多幻ios用户";
  return visitor;
}

@end
