//
//  SecondViewController.m
//  test11
//
//  Created by 胜皓唐 on 2020/6/23.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "SecondViewController.h"
#import "TestObject.h"

@interface SecondViewController ()



@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //ARC会自动将其 默认用__strong修饰 并且作用域范围后会将其释放
    TestObject *test1 = [TestObject new];
    
    
    
}



@end
