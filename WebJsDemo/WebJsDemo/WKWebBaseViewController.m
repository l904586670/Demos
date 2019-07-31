//
//  WKWebBaseViewController.m
//  WebJsDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "WKWebBaseViewController.h"

#import "DHWeakProxy.h"

static void * const kEstimatedProgressObserverContent = @"estimatedProgressContent";
static void * const kTitleObserverContent = @"jsTitleContent";

@interface WKWebBaseViewController ()<WKUIDelegate,
                                      WKNavigationDelegate,
                                      WKScriptMessageHandler>

@property (nonatomic, strong) NSArray <NSString *>*scriptNames;

@property (nonatomic, assign) UIEdgeInsets safeEdgeInsets;
@property (nonatomic, strong) DHWeakProxy *weakProxy;


@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation WKWebBaseViewController

- (instancetype)initWithScriptMessageNames:(nullable NSArray <NSString *>*)scriptNames {
  if (self = [super init]) {
    _scriptNames = scriptNames;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
 
  [self progressView];
  
  [self webView];
  
  [self addObserver];
  
  UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  backBtn.frame = CGRectMake(0, 0, 100, 50);
  backBtn.backgroundColor = [UIColor redColor];
  [self.view addSubview:backBtn];
  
  [backBtn addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];
}

- (void)onBack {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
  NSLog(@"WKWebViewController dealloc");
}

#pragma mark - Lazy Methods

- (UIEdgeInsets)safeEdgeInsets {
  UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
  if (@available(iOS 11.0, *)) {
    safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
  }
  return safeAreaInsets;
}

- (WKWebView *)webView {
  if (!_webView) {
    CGRect frame = UIEdgeInsetsInsetRect(self.view.bounds, self.safeEdgeInsets);
    
    // 创建网页配置对象
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    
    WKPreferences *preference = [[WKPreferences alloc] init];
    //最小字体大小 当将javaScriptEnabled属性设置为NO时，可以看到明显的效果
    preference.minimumFontSize = 14.0;
    //设置是否支持javaScript 默认是支持的
    preference.javaScriptEnabled = YES;
    // 在iOS上默认为NO，表示是否允许不经过用户交互由javaScript自动打开窗口
    preference.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preference;
    
    // 是使用h5的视频播放器在线播放, 还是使用原生播放器全屏播放
    configuration.allowsInlineMediaPlayback = YES;
    //设置视频是否需要用户手动播放  设置为NO则会允许自动播放
    if (@available(iOS 10.0, *)) {
      configuration.mediaTypesRequiringUserActionForPlayback = YES;
    } else {
      // Fallback on earlier versions
    }
    //设置是否允许画中画技术 在特定设备上有效
    configuration.allowsPictureInPictureMediaPlayback = YES;
    // 设置请求的User-Agent信息中应用程序名称 iOS9后可用
    configuration.applicationNameForUserAgent = @"appName";
    
    //自定义的WKScriptMessageHandler 是为了解决内存不释放的问题
    _weakProxy = [DHWeakProxy proxyWithTarget:self];
    
    //这个类主要用来做native与JavaScript的交互管理
    WKUserContentController * wkUController = [[WKUserContentController alloc] init];
    
    // 注册js的方法名 设置处理接收JS方法的对象
    for (NSString *name in _scriptNames) {
      [wkUController addScriptMessageHandler:(id<WKScriptMessageHandler>)_weakProxy name:name];
    }
  
    configuration.userContentController = wkUController;
    
    //以下代码适配文本大小
    NSString *jSString = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
    //用于进行JavaScript注入
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jSString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:wkUScript];
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:frame configuration:configuration];
    [self.view addSubview:webView];
    webView.UIDelegate = self;
    // 导航代理
    webView.navigationDelegate = self;
    // 是否允许手势左滑返回上一级, 类似导航控制的左滑返回
    webView.allowsBackForwardNavigationGestures = YES;
    //可返回的页面列表, 存储已打开过的网页
    //  WKBackForwardList * backForwardList = [webView backForwardList];
    
    //页面后退
    //  [webView goBack];
    //页面前进
    //  [webView goForward];
    //刷新当前页面
//    [webView reload];
    
    _webView = webView;
  }
  return _webView;
}

- (UIProgressView *)progressView {
  if (!_progressView) {
    CGRect frame = CGRectMake(0, self.safeEdgeInsets.top, self.view.frame.size.width, 2);
    _progressView = [[UIProgressView alloc] initWithFrame:frame];
    _progressView.tintColor = [UIColor blueColor];
    _progressView.trackTintColor = [UIColor clearColor];
    [self.view addSubview:_progressView];
  }
  return _progressView;
}

#pragma mark - Public Methods

- (void)loadLocalHtmlWithName:(NSString *)htmlName {
  NSString *path = [[NSBundle mainBundle] pathForResource:htmlName ofType:@"html"];
  NSError *error = nil;
  NSString *htmlString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
  if (error) {
    NSLog(@"load local html error : %@", error.description);
    NSAssert(NO, @"load local html fail");
    return;
  }
  //加载本地html文件
  [self.webView loadHTMLString:htmlString
                       baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}

- (void)requesetWithUrlString:(NSString *)urlString {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [request addValue:[self readCurrentCookieWithDomain:urlString] forHTTPHeaderField:@"Cookie"];
  [self.webView loadRequest:request];
}

- (void)goBackAction {
  if ([_webView canGoBack]) {
    [_webView goBack];
  }
}

- (void)goForwardAction {
  if ([_webView canGoForward]) {
    [_webView goForward];
  }
}

- (void)onRefreshAction {
  [_webView reload];
}

- (void)sendMessageToJSWith:(NSString *)js resultHandler:(void(^)(id data, NSError *error))result {
  if (!js) {
    return;
  }
  
  [_webView evaluateJavaScript:js completionHandler:result];
}

#pragma mark - Private Methods

- (void)addObserver {
  //添加监测网页加载进度的观察者
  [self.webView addObserver:self
                 forKeyPath:@"estimatedProgress"
                    options:NSKeyValueObservingOptionNew
                    context:kEstimatedProgressObserverContent];
  
  [self.webView addObserver:self
                 forKeyPath:@"title"
                    options:NSKeyValueObservingOptionNew
                    context:kTitleObserverContent];
}

//解决第一次进入的cookie丢失问题
- (NSString *)readCurrentCookieWithDomain:(NSString *)domainStr {
  NSHTTPCookieStorage*cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSMutableString * cookieString = [[NSMutableString alloc]init];
  for (NSHTTPCookie*cookie in [cookieJar cookies]) {
    [cookieString appendFormat:@"%@=%@;",cookie.name,cookie.value];
  }
  
  //删除最后一个“;”
  if ([cookieString hasSuffix:@";"]) {
    [cookieString deleteCharactersInRange:NSMakeRange(cookieString.length - 1, 1)];
  }
  
  return cookieString;
}

// 解决 页面内跳转（a标签等）还是取不到cookie的问题
- (void)getCookie {
  
  //取出cookie
  NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  //js函数
  NSString *JSFuncString =
  @"function setCookie(name,value,expires)\
  {\
  var oDate=new Date();\
  oDate.setDate(oDate.getDate()+expires);\
  document.cookie=name+'='+value+';expires='+oDate+';path=/'\
  }\
  function getCookie(name)\
  {\
  var arr = document.cookie.match(new RegExp('(^| )'+name+'=([^;]*)(;|$)'));\
  if(arr != null) return unescape(arr[2]); return null;\
  }\
  function delCookie(name)\
  {\
  var exp = new Date();\
  exp.setTime(exp.getTime() - 1);\
  var cval=getCookie(name);\
  if(cval!=null) document.cookie= name + '='+cval+';expires='+exp.toGMTString();\
  }";
  
  //拼凑js字符串
  NSMutableString *JSCookieString = JSFuncString.mutableCopy;
  for (NSHTTPCookie *cookie in cookieStorage.cookies) {
    NSString *excuteJSString = [NSString stringWithFormat:@"setCookie('%@', '%@', 1);", cookie.name, cookie.value];
    [JSCookieString appendString:excuteJSString];
  }
  //执行js
  [_webView evaluateJavaScript:JSCookieString completionHandler:nil];
}

#pragma mark - KVO Action

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if (context == kEstimatedProgressObserverContent) {
    
    //    NSLog(@"网页加载进度 = %f",_webView.estimatedProgress);
    self.progressView.progress = _webView.estimatedProgress;
    if (_webView.estimatedProgress >= 1.0f) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.progressView.progress = 0;
      });
    }
  } else if (context == kTitleObserverContent){
    //    self.navigationItem.title = _webView.title;
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark - WKScriptMessageHandler

// 收到js消息时调用
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
  NSLog(@"name:%@\\\\n body:%@\\\\n frameInfo:%@\\\\n",message.name,message.body,message.frameInfo);
  //用message.body获得JS传出的参数体
  NSDictionary *parameter = message.body;
  
  // JS调用OC
  if (_scriptNames) {
    if (![_scriptNames containsObject:message.name]) {
      // 没在注册的方法名称里面, 不处理
      return;
    }
    
    NSString *selectorName = [NSString stringWithFormat:@"%@:", message.name];
    SEL selector = NSSelectorFromString(selectorName);
    if ([self respondsToSelector:selector]) {
      IMP imp = [self methodForSelector:selector];
      void (*func)(id, SEL, NSDictionary *) = (void *)imp;
      func(self, selector, parameter);
//      [self performSelector:selector withObject:parameter];
    } else {
      NSAssert(NO, @"控制器没有实现方法 : %@", message.name);
    }

  } else {
    // 没有注册
    
//    NSString *selectorName = [NSString stringWithFormat:@"%@:", message.name];
//    SEL selector = NSSelectorFromString(selectorName);
//    if ([self respondsToSelector:selector]) {
//      IMP imp = [self methodForSelector:selector];
//      void (*func)(id, SEL) = (void *)imp;
//      func(self, selector);
//      //      [self performSelector:selector withObject:parameter];
//    } else {
//      NSAssert(NO, @"控制器没有实现方法 : %@", message.name);
//    }
  }
}

#pragma mark -- WKNavigationDelegate

// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
  [self getCookie];
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
  [self.progressView setProgress:0.0f animated:NO];
}

// 根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  NSString * urlStr = navigationAction.request.URL.absoluteString;
  NSLog(@"发送跳转请求：%@",urlStr);
  
  // 根据urlStr 做一些拦截工作
  NSString *htmlHeadString = @"github://";
  if([urlStr hasPrefix:htmlHeadString]){
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"通过截取URL调用OC" message:@"你想前往我的Github主页?" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
      
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      NSURL * url = [NSURL URLWithString:[urlStr stringByReplacingOccurrencesOfString:@"github://callName_?" withString:@""]];
      
      if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url
                                           options:@{}
                                 completionHandler:nil];
      } else {
        [[UIApplication sharedApplication] openURL:url];
      }
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
    
    decisionHandler(WKNavigationActionPolicyCancel);
    return;
  }
  
  decisionHandler(WKNavigationActionPolicyAllow);
}

// 根据客户端受到的服务器响应头以及response相关信息来决定是否可以跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
  NSString * urlStr = navigationResponse.response.URL.absoluteString;
  NSLog(@"当前跳转地址：%@",urlStr);
  //允许跳转
  decisionHandler(WKNavigationResponsePolicyAllow);
  //不允许跳转
  //decisionHandler(WKNavigationResponsePolicyCancel);
}

// 需要响应身份验证时调用 同样在block中需要传入用户身份凭证
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
  NSURLCredential * newCred = [[NSURLCredential alloc] initWithUser:@"user123" password:@"123" persistence:NSURLCredentialPersistenceNone];
  //为 challenge 的发送方提供 credential
  [challenge.sender useCredential:newCred forAuthenticationChallenge:challenge];
  completionHandler(NSURLSessionAuthChallengeUseCredential,newCred);
}

// 进程被终止时调用
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
}

#pragma mark -- WKUIDelegate

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
  if (!navigationAction.targetFrame.isMainFrame) {
    [webView loadRequest:navigationAction.request];
  }
  return nil;
}

/*! @abstract Notifies your app that the DOM window object's close() method completed successfully.
 @param webView The web view invoking the delegate method.
 @discussion Your app should remove the web view from the view hierarchy and update
 the UI as needed, such as by closing the containing browser tab or window.
 */
- (void)webViewDidClose:(WKWebView *)webView {
}

// web界面中有弹出警告框时调用
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
  
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:([UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    completionHandler();
  }])];
  [self presentViewController:alertController animated:YES completion:nil];
}

// 确认框
//JavaScript调用confirm方法后回调的方法 confirm是js中的确定框，需要在block中把用户选择的情况传递进去
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认框" message:message preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    completionHandler(YES);
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    completionHandler(NO);
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

// 输入框
//JavaScript调用prompt方法后回调的方法 prompt是js中的输入框 需要在block中把用户输入的信息传入
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:prompt preferredStyle:UIAlertControllerStyleAlert];
  [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
    textField.textColor = [UIColor blackColor];
    textField.text = defaultText;
  }];
  [alertController addAction:([UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    completionHandler(alertController.textFields[0].text?:@"");
  }])];
  [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    completionHandler(nil);
  }]];
  [self presentViewController:alertController animated:YES completion:nil];
}


@end
