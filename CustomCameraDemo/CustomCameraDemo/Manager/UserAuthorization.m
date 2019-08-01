//
//  UserAuthorization.m
//
//  Created by yiqux on 2017/5/3.
//  Copyright © 2017年 yiqux. All rights reserved.
//

#import "UserAuthorization.h"

// 相机，麦克风
#import <AVFoundation/AVFoundation.h>

// 相册
#import <Photos/Photos.h>

// 通讯录
#import <AddressBook/AddressBook.h>
#import <Contacts/Contacts.h>

// 定位
#import <CoreLocation/CoreLocation.h>

// 日历 备忘录
#import <EventKit/EventKit.h>

// 消息通知
@import UserNotifications;

// *******************************************************************************

@implementation UserAuthorization

#pragma mark - 跳转到设置页面改变权限状态

+ (void)gotoPermissionPage {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:NULL];
}

+ (void)showChangePermissionAlert:(NSString *)message viewController:(UIViewController *)viewController {
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"前往" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [[self class] gotoPermissionPage];
  }];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"算了" style:UIAlertActionStyleCancel handler:nil];
  
  [alertController addAction:sureAction];
  [alertController addAction:cancelAction];

  [viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - 请求相册权限

+ (void)requestAlbumPermission:(authorizedBlock)authorizedCallback
                 deniedHandler:(deniedBlock)deniedCallback {
  if (!(authorizedCallback && deniedCallback)) {
    return;
  }
  
  PHAuthorizationStatus photoAuthStatus = [PHPhotoLibrary authorizationStatus];
  switch (photoAuthStatus) {
    case PHAuthorizationStatusNotDetermined: {
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (PHAuthorizationStatusAuthorized == status) {
            authorizedCallback();
          } else {
            deniedCallback(status);
          }
        });
      }];
      break;
    }
    case PHAuthorizationStatusRestricted:
      deniedCallback(photoAuthStatus);
      break;
    case PHAuthorizationStatusDenied:
      deniedCallback(photoAuthStatus);
      break;
    case PHAuthorizationStatusAuthorized:
      authorizedCallback();
      break;
  }
}

#pragma mark - 请求相机 和 麦克风 权限

+ (void)requestCameraOrMicrophonePermission:(BOOL)isCamera
                          authorizedHandler:(authorizedBlock)authorizedCallback
                              deniedHandler:(deniedBlock)deniedCallback {
  if (!authorizedCallback || !deniedCallback) {
    return;
  }
  
  NSString *mediaType = isCamera ? AVMediaTypeVideo : AVMediaTypeAudio;
  AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
  
  switch (videoAuthStatus) {
    case AVAuthorizationStatusNotDetermined: {
      [AVCaptureDevice requestAccessForMediaType:mediaType
                               completionHandler:^(BOOL granted) {
        
                                 if ([NSThread isMainThread]) {
                                   if (granted) {
                                     authorizedCallback();
                                   } else {
                                     deniedCallback(AVAuthorizationStatusDenied);
                                   }
                                 } else {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                     if (granted) {
                                       authorizedCallback();
                                     } else {
                                       deniedCallback(AVAuthorizationStatusDenied);
                                     }
                                   });
                                 }
        
      }];
      break;
    }
    case AVAuthorizationStatusRestricted:
      deniedCallback(videoAuthStatus);
      break;
    case AVAuthorizationStatusDenied:
      deniedCallback(videoAuthStatus);
      break;
    case AVAuthorizationStatusAuthorized:
      authorizedCallback();
      break;
  }
}

#pragma mark - 请求通知权限

+ (void)registerNotificationPermission {
  UNAuthorizationOptions options = (UNAuthorizationOptionBadge |
                                    UNAuthorizationOptionAlert |
                                    UNAuthorizationOptionSound);
  
  [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
  }];
}

+ (void)getNotificationPermissionStatus:(notificationPermissionBlock)completionHandler {
  if (!completionHandler) {
    return;
  }
  
  [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
    dispatch_async(dispatch_get_main_queue(), ^{
      completionHandler(UNAuthorizationStatusAuthorized == settings.authorizationStatus);
    });
  }];
}

#pragma mark - 请求通讯录权限

+ (void)requestAddressPermission:(authorizedBlock)authorizedCallback
                   deniedHandler:(deniedBlock)deniedCallback {
  if (!(authorizedCallback && deniedCallback)) {

    return;
  }
  
  CNAuthorizationStatus authorizationStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
  switch (authorizationStatus) {
    case CNAuthorizationStatusNotDetermined: {
      CNContactStore *contact = [[CNContactStore alloc] init];
      [contact requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (granted) {
            authorizedCallback();
          } else {
            deniedCallback(CNAuthorizationStatusDenied);
          }
        });
      }];
      break;
    }
    case CNAuthorizationStatusRestricted:
      deniedCallback(authorizationStatus);
      break;
    case CNAuthorizationStatusDenied:
      deniedCallback(authorizationStatus);
      break;
    case CNAuthorizationStatusAuthorized:
      authorizedCallback();
      break;
  }
}

#pragma mark - 日历 和 备忘录

+ (void)requestCalendarOrMemorandumPermission:(BOOL)isCalendar
                            authorizedHandler:(authorizedBlock)authorizedCallback
                                deniedHandler:(deniedBlock)deniedCallback {
  if (!(authorizedCallback && deniedCallback)) {
    return;
  }
  
  NSUInteger entityType = isCalendar ? EKEntityTypeEvent : EKEntityTypeReminder;
  EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:entityType];
  switch (status) {
    case EKAuthorizationStatusNotDetermined: {
      EKEventStore *eventStore = [[EKEventStore alloc] init];
      [eventStore requestAccessToEntityType:entityType completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (granted) {
            authorizedCallback();
          } else {
            deniedCallback(EKAuthorizationStatusDenied);
          }
        });
      }];
      break;
    }
    case EKAuthorizationStatusRestricted:
      deniedCallback(status);
      break;
    case EKAuthorizationStatusDenied:
      deniedCallback(status);
      break;
    case EKAuthorizationStatusAuthorized:
      authorizedCallback();
      break;
  }
}

#pragma mark - 定位权限

+ (BOOL)getLocationServicesStatus {
  return [CLLocationManager locationServicesEnabled];
}

+ (void)requestLocationPermission:(BOOL)always {
  CLLocationManager *manager = [[CLLocationManager alloc] init];
  if (always) {
    [manager requestAlwaysAuthorization];
  } else {
    [manager requestWhenInUseAuthorization];
  }
}

+ (BOOL)getLocationPermissionStatus {
  CLAuthorizationStatus locationStatus = [CLLocationManager authorizationStatus];
  switch (locationStatus) {
    case kCLAuthorizationStatusNotDetermined:
    case kCLAuthorizationStatusRestricted:
    case kCLAuthorizationStatusDenied:
      return NO;
    case kCLAuthorizationStatusAuthorizedAlways:
    case kCLAuthorizationStatusAuthorizedWhenInUse:
      return YES;
  }
}

@end
