//
//  AppDelegate+Other.h
//  HuanXingKefuDemo
//
//  Created by User on 2019/7/18.
//  Copyright © 2019 Rock. All rights reserved.
//
// 在此拓展中实现 环信 和 极光 的注册和代理方法
// 在没有用runtime 交换方法的情况下,不要在此拓展中实现 appDelegate 的方法

#import "AppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate (Other)

// 注册配置
- (void)initConfigApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

// 收到用户推送token
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

- (void)resetCustomerServiceSDK;
- (void)userAccountDidRemoveFromServer;
- (void)userAccountDidLoginFromOtherDevice;

@end

NS_ASSUME_NONNULL_END
