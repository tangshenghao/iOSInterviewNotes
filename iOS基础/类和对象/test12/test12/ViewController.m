//
//  ViewController.m
//  test12
//
//  Created by 胜皓唐 on 2020/6/26.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "TestObject.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    TestObject *test1 = [[TestObject alloc] init];
    TestObject *test2 = [[TestObject alloc] init];
    
    NSLog(@"test1 : %p   test2 : %p", test1, test2);
    
    
    Class testClass1 = [TestObject class];
    Class testClass2 = [test1 class];
    
    NSLog(@"testClass1 : %p , testClass2 : %p", testClass1, testClass2);
    
}


@end
