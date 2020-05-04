//
//  ViewController.m
//  ObjDemo
//
//  Created by Rock on 2019/3/12.
//  Copyright © 2019 Yiqux. All rights reserved.
//

#import "ViewController.h"

#import "Person.h"
#import "PersonModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

  [self test];
}


- (void)test {
  NSMutableArray *persons = [NSMutableArray array];
  for (NSInteger i = 0; i < 10; i++) {

    Person *person = [[Person alloc] initWithModel:[PersonModel randomModel]];
    person.index = i;
    [persons addObject:person];
  }

  Person *oneP = [persons[0] copy];
  [persons addObject:oneP];

  NSMutableArray *newPersons = [NSMutableArray array];
  while (newPersons.count < 9) {
    NSInteger randomIndex = arc4random() % persons.count;

    if (![newPersons containsObject:persons[randomIndex]]) {
      [newPersons addObject:persons[randomIndex]];
    }
  }

  for (Person *person in newPersons) {
    NSLog(@"name : %@", @(person.index));
  }
}

/**
 1. 对象属性
 */


@end
