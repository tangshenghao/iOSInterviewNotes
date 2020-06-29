//
//  ViewController.m
//  test13
//
//  Created by 胜皓唐 on 2020/6/28.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "TestObject.h"
#import "NSObject+JSONExtension.h"
#import "TestObjectThree.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    TestObject *test = [[TestObject alloc] init];
    [test performSelector:@selector(logTest)];

    [TestObject performSelector:@selector(logTest)];
    
    
    NSDictionary *dic = @{@"name":@"啊啊啊", @"number":@(1), @"other":@"xxx"};
    
    TestObjectThree *three = [[TestObjectThree alloc] initWithDictionary:dic];
    NSLog(@"name : %@, count : %d", three.name, three.number);
    
    // 以下代码会崩溃
//    TestObjectThree *three = [[TestObjectThree alloc] init];
//    [three setValuesForKeysWithDictionary:dic];
}

- (void)viewDidAppear:(BOOL)animated {
    
    NSLog(@"viewDidAppear super前");
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear super后");
}


@end
