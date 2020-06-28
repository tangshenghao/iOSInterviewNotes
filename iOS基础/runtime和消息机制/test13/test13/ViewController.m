//
//  ViewController.m
//  test13
//
//  Created by 胜皓唐 on 2020/6/28.
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
    
    TestObject *test = [[TestObject alloc] init];
//    [test performSelector:@selector(logTest)];

    [TestObject performSelector:@selector(logTest)];
    
}


@end
