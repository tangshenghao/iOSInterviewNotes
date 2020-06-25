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

@property (nonatomic, weak) TestObject *test2;

@property (nonatomic, weak) NSString *test3;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton addTarget:self action:@selector(backVC) forControlEvents:UIControlEventTouchUpInside];
    [backButton setFrame:CGRectMake(20, 100, 100, 60)];
    [backButton setTitle:@"返回" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:backButton];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //ARC会自动将其 默认用__strong修饰 并且作用域范围后会将其释放
    TestObject *test1 = [TestObject new];
    
    self.test2 = test1;

    NSLog(@"===viewDidLoad==%@",self.test2);
    
    
    NSString *str;
    @autoreleasepool {
        str = [NSString stringWithFormat:@"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"];
        self.test3 = str;
    }
    NSLog(@"===viewDidLoad==str = %p", self.test3);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"===viewWillAppear==%@===str = %p",self.test2, self.test3);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"===viewDidAppear==%@===str = %p",self.test2, self.test3);
}

- (void)backVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    NSLog(@"销毁SecondVC");
}
@end
