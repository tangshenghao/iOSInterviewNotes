//
//  ViewController.m
//  test17
//
//  Created by 胜皓唐 on 2020/7/7.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "TestObject+plugin.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    TestObject *test = [[TestObject alloc] init];
    [test testLog4];
    [test testLog2];
//    test.testString = @"123";
}


@end
