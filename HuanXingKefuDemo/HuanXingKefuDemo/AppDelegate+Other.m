//
//  AppDelegate+Other.m
//  HuanXingKefuDemo
//
//  Created by User on 2019/7/18.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "AppDelegate+Other.h"

@interface AppDelegate ()<JPUSHRegisterDelegate,HDClientDelegate>

@end

@implementation AppDelegate (Other)

#pragma mark - Public Methods

- (void)initConfigApplication:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  [self initializeJPushConfigWith:launchOptions];
  //ios8注册apns
  [self registerRemoteNotification];
  //初始化环信客服sdk
  [self initializeCustomerServiceSdk];
  
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
  [audioSession setActive:YES error:nil];
  
  [self registerSystomNotification];
}

// 收到用户设备token
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  // 把token 上传给环信
  dispatch_async(dispatch_get_main_queue(), ^{
    [[HDClient sharedClient] bindDeviceToken:deviceToken];
  });

  // 把token 上传给极光
  [JPUSHService registerDeviceToken:deviceToken];
}

- (void)resetCustomerServiceSDK {
  //如果在登录状态,账号要退出
  HDClient *client = [HDClient sharedClient];
  HDError *error = [client logout:NO];
  if (error != nil) {
    NSLog(@"登出出错:%@",error.errorDescription);
  }
  CSDemoAccountManager *lgM = [CSDemoAccountManager shareLoginManager];
  HDError *er = [client changeAppKey:lgM.appkey];
  if (er == nil) {
    [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"appkey_updated", @"Appkey has been updated")];
    [SVProgressHUD dismissWithDelay:1.0];
    NSLog(@"appkey 已更新");
  } else {
    NSLog(@"appkey 更新失败,请手动重启");
  }
}

- (void)userAccountDidRemoveFromServer {
  [self userAccountLogout];
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompta", @"Prompt") message:NSLocalizedString(@"loginUserRemoveFromServer", @"your login account has been remove from server") delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
  [alertView show];
}

- (void)userAccountDidLoginFromOtherDevice {
  [self userAccountLogout];
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompta", @"Prompt") message:NSLocalizedString(@"loginAtOtherDevice", @"your login account has been in other places") delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
  [alertView show];
}

#pragma mark - Private Methods

- (void)registerRemoteNotification {
  UIApplication *application = [UIApplication sharedApplication];
  application.applicationIconBadgeNumber = 0;
  
  if([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
    UIUserNotificationType notificationTypes = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
    [application registerUserNotificationSettings:settings];
  }
  
#if !TARGET_IPHONE_SIMULATOR
  [application registerForRemoteNotifications];
#endif
}

- (void)initializeJPushConfigWith:(NSDictionary *)launchOptions {
  JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
  if (@available(iOS 12.0, *)) {
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound|JPAuthorizationOptionProvidesAppNotificationSettings;
  } else {
    entity.types = JPAuthorizationOptionAlert|JPAuthorizationOptionBadge|JPAuthorizationOptionSound;
    // Fallback on earlier versions
  }
  if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
    // 可以添加自定义 categories
    // NSSet<UNNotificationCategory *> *categories for iOS10 or later
    // NSSet<UIUserNotificationCategory *> *categories for iOS8 and iOS9
  }
  [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
  
  // Required
  // init Push
  // notice: 2.1.5 版本的 SDK 新增的注册方法，改成可上报 IDFA，如果没有使用 IDFA 直接传 nil
  [JPUSHService setupWithOption:launchOptions appKey:@"e607005e5980f429fee42ed1"
                        channel:@"APP Store"
               apsForProduction:YES
          advertisingIdentifier:nil];
  
  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
  [JPUSHService setBadge:0];
}

//初始化客服sdk
- (void)initializeCustomerServiceSdk {

  // 推送证书的名称(上传环信推送时自己起的名称)
  NSString *apnsCertName = nil;
#if DEBUG
  apnsCertName = @"duohuanAPNS";
#else
  apnsCertName = @"duohuanAPNS";
#endif
  //注册kefu_sdk
  CSDemoAccountManager *lgM = [CSDemoAccountManager shareLoginManager];
  HDOptions *option = [[HDOptions alloc] init];
  option.appkey = lgM.appkey;
  option.tenantId = lgM.tenantId;
  option.enableConsoleLog = NO; // 是否打开日志信息
  option.apnsCertName = apnsCertName;
  option.visitorWaitCount = YES; // 打开待接入访客排队人数功能
  option.showAgentInputState = YES; // 是否显示坐席输入状态
  HDClient *client = [HDClient sharedClient];
  HDError *initError = [client initializeSDKWithOptions:option];
  if (initError) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"initialization_error", @"Initialization error!") message:initError.errorDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
    [alert show];
    return;
  }
  
  [self registerEaseMobNotification];
  
}

- (void)registerEaseMobNotification {
  // 将self 添加到SDK回调中，以便本类可以收到SDK回调
  [[HDClient sharedClient] addDelegate:self delegateQueue:nil];
}

- (void)unRegisterEaseMobNotification{
  [[HDClient sharedClient] removeDelegate:self];
}

- (void)userAccountLogout {
  [[HDClient sharedClient] logout:YES];
  HDChatViewController *chat = [CSDemoAccountManager shareLoginManager].curChat;
  if (chat) {
    [chat backItemClicked];
  }
}

#pragma mark - Notification

// 监听系统生命周期回调，以便将需要的事件传给SDK
- (void)registerSystomNotification {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appDidEnterBackgroundNotif:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appWillEnterForeground:)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appDidFinishLaunching:)
                                               name:UIApplicationDidFinishLaunchingNotification
                                             object:nil];
  
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appDidBecomeActiveNotif:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appWillResignActiveNotif:)
                                               name:UIApplicationWillResignActiveNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appDidReceiveMemoryWarning:)
                                               name:UIApplicationDidReceiveMemoryWarningNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appWillTerminateNotif:)
                                               name:UIApplicationWillTerminateNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appProtectedDataWillBecomeUnavailableNotif:)
                                               name:UIApplicationProtectedDataWillBecomeUnavailable
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appProtectedDataDidBecomeAvailableNotif:)
                                               name:UIApplicationProtectedDataDidBecomeAvailable
                                             object:nil];
}

- (void)appDidEnterBackgroundNotif:(NSNotification*)notif {
  [[HDClient sharedClient] applicationDidEnterBackground:notif.object];
}

- (void)appWillEnterForeground:(NSNotification*)notif {
  [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
  [[HDClient sharedClient] applicationWillEnterForeground:notif.object];
}

- (void)appDidFinishLaunching:(NSNotification*)notif {
  //    [[HDClient sharedClient] applicationdidfinishLounching];
  //   [[EaseMob sharedInstance] applicationDidFinishLaunching:notif.object];
}

- (void)appDidBecomeActiveNotif:(NSNotification*)notif {
  //  [[EaseMob sharedInstance] applicationDidBecomeActive:notif.object];
}

- (void)appWillResignActiveNotif:(NSNotification*)notif {
  //   [[EaseMob sharedInstance] applicationWillResignActive:notif.object];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"closeRecording" object:nil];
}

- (void)appDidReceiveMemoryWarning:(NSNotification*)notif {
  //   [[EaseMob sharedInstance] applicationDidReceiveMemoryWarning:notif.object];
}

- (void)appWillTerminateNotif:(NSNotification*)notif {
  //    [[EaseMob sharedInstance] applicationWillTerminate:notif.object];
}

- (void)appProtectedDataWillBecomeUnavailableNotif:(NSNotification*)notif {
}

- (void)appProtectedDataDidBecomeAvailableNotif:(NSNotification*)notif {
}

#pragma mark - JPUSHRegisterDelegate

// iOS 12 Support
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification {
  NSLog(@"从通知界面进入app");
  
  if (notification && [notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
    //从通知界面直接进入应用
    
  } else {
    //从通知设置界面进入应用
  }
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
  // Required
  NSDictionary * userInfo = notification.request.content.userInfo;
  if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
    [JPUSHService handleRemoteNotification:userInfo];
  }
  completionHandler(UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有 Badge、Sound、Alert 三种类型可以选择设置
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
  // Required
  NSDictionary * userInfo = response.notification.request.content.userInfo;
  if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
    [JPUSHService handleRemoteNotification:userInfo];
  }
  completionHandler();  // 系统要求执行这个方法
}

#pragma clang diagnostic pop

// 收到远程推送通知
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  
  // Required, iOS 7 Support
  [JPUSHService handleRemoteNotification:userInfo];
  completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  
  // Required, For systems with less than or equal to iOS 6
  [JPUSHService handleRemoteNotification:userInfo];
}


@end
