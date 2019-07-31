//
//  UserAuthorization.h
//
//  Created by yiqux on 2017/5/3.
//  Copyright © 2017年 yiqux. All rights reserved.
//

/*
 IOS 10.0 以后请求权限要在Info.plist文件中添加对应key值
 相册权限    Privacy - Photo Library Usage Description
 相机权限    Privacy - Camera Usage Description
 麦克风      Privacy - Microphone Usage Description
 通讯录      Privacy - Contacts Usage Description
 日历       Privacy - Calendars Usage Description
 提醒事项    Privacy - Reminders Usage Description
 定位       Privacy - Location When In Use Usage Description (使用App时开启定位服务)
           Privacy - Location Always Usage Description (一直开启定位服务)
 */

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

// 用户同意授权后的回调
typedef void(^authorizedBlock)(void);

// 用户拒绝后的回调, authStatus == 1 受限制(家长控制) authStatus == 2 用户拒绝
typedef void(^deniedBlock)(NSInteger authStatus);

// 查询消息通知的状态的回调，allowed == YES表示用户允许，NO表示用户拒绝
typedef void(^notificationPermissionBlock)(BOOL allowed);

// *******************************************************************************

@interface UserAuthorization : NSObject

/**
 苹果默认前往设置页面更改用户权限方法
 */
+ (void)gotoPermissionPage;

+ (void)showChangePermissionAlert:(NSString *)message viewController:(UIViewController *)viewController;

/**
 查询相册权限, 首次查询会请求相册权限

 @param authorizedCallback 同意后的回调
 @param deniedCallback 拒绝后的回调
 */
+ (void)requestAlbumPermission:(authorizedBlock)authorizedCallback
                 deniedHandler:(deniedBlock)deniedCallback;

/**
 查询用户相机或者麦克风权限.

 @param isCamera 查询是否为相机
 @param authorizedCallback 同意回调
 @param deniedCallback 拒绝回调
 */
+ (void)requestCameraOrMicrophonePermission:(BOOL)isCamera
                          authorizedHandler:(authorizedBlock)authorizedCallback
                              deniedHandler:(deniedBlock)deniedCallback;

/**
 弹出请求通知权限Alert. 此方法多次调用Alert只会弹一次
 */
+ (void)registerNotificationPermission;

/**
 查询当前通知状态是否为关闭状态, 如果是关闭状态,要先请求下通知权限(otherwise: 可能出现跳转到设置里面没有通知的开关)
 
 @param completionHandler 回调
 */
+ (void)getNotificationPermissionStatus:(notificationPermissionBlock)completionHandler;

/**
 请求通讯录权限

 @param authorizedCallback 同意回调
 @param deniedCallback 拒绝回调
 */
+ (void)requestAddressPermission:(authorizedBlock)authorizedCallback
                   deniedHandler:(deniedBlock)deniedCallback;

/**
 请求日历或者备忘录权限

 @param isCalendar YES 日历
 @param authorizedCallback 同意回调
 @param deniedCallback 用户拒绝回调
 */
+ (void)requestCalendarOrMemorandumPermission:(BOOL)isCalendar
                            authorizedHandler:(authorizedBlock)authorizedCallback
                                deniedHandler:(deniedBlock)deniedCallback;

/**
 判断用户是否开启定位服务

 @return YES 开启
 */
+ (BOOL)getLocationServicesStatus;

/**
 判断用户是否同意过开启定位权限, 没有请求过和拒绝返回均为NO

 @return YES 已开启
 */
+ (BOOL)getLocationPermissionStatus;

/**
 请求定位权限, 分为一直开启定位和使用时开启定位

 @param always YES 一直开启定位服务, 一般设置为NO
 */
+ (void)requestLocationPermission:(BOOL)always;

@end
