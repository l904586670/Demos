//
//  ViewController.m
//  WebJsDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "ViewController.h"

#import "WebTestViewController.h"


// WKScriptMessageHandler 这个协议类专门用来处理JavaScript调用原生OC的方法
@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor whiteColor];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  WebTestViewController *testVC = [[WebTestViewController alloc] init];
  [self presentViewController:testVC animated:YES completion:nil];
}


@end
