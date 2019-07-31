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


- (instancetype)initWithScriptMessageNames:(nullable NSArray <NSString *>*)scriptNames;

- (void)loadLocalHtmlWithName:(NSString *)htmlName;

- (void)requesetWithUrlString:(NSString *)urlString;

// 后退
- (void)goBackAction;
// 前进
- (void)goForwardAction;
// 刷新
- (void)onRefreshAction;

@end

NS_ASSUME_NONNULL_END
