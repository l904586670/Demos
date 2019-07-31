//
//  WebTestViewController.m
//  WebJsDemo
//
//  Created by User on 2019/7/31.
//  Copyright © 2019 Rock. All rights reserved.
//

#import "WebTestViewController.h"

@interface WebTestViewController ()

@end

@implementation WebTestViewController

- (instancetype)init {
  self = [super initWithScriptMessageNames:@[ @"jsToOcWithPrams", @"jsToOcNoPrams" ]];
  if (self) {
    
  }
  return self;
}
  

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self loadLocalHtmlWithName:@"JStoOC"];
  
}

- (void)jsToOcWithPrams:(NSDictionary *)dict {
  
}

- (void)jsToOcNoPrams:(NSDictionary *)dict {
  
}


@end
