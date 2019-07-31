//
//  WKWebBaseViewController.h
//  WebJsDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
// 参考: https://www.jianshu.com/p/5cf0d241ae12

#import <UIKit/UIKit.h>

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebBaseViewController : UIViewController

@property (nonatomic, strong, readonly) WKWebView *webView;

@property (nonatomic, strong, readonly) UIProgressView *progressView;


/**
 初始化方法

 @param scriptNames 注册js sendMessageToOc的方法名,在子类控制器中实现这些方法
 @return Web控制器
 */
- (instancetype)initWithScriptMessageNames:(nullable NSArray <NSString *>*)scriptNames;

- (void)loadLocalHtmlWithName:(NSString *)htmlName;

- (void)requesetWithUrlString:(NSString *)urlString;

// 后退
- (void)goBackAction;
// 前进
- (void)goForwardAction;
// 刷新
- (void)onRefreshAction;

/**
 发送消息到JS. JS 里面定义好方法名称.

 @param js JS里面定义好的方法名和参数拼接的字符串 func(parameter). eg : changeColor(#000000)
 @param result 结果回调
 */
- (void)sendMessageToJSWith:(NSString *)js resultHandler:(void(^)(id data, NSError *error))result;

@end

NS_ASSUME_NONNULL_END
