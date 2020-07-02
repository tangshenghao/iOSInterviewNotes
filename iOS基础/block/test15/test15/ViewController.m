//
//  ViewController.m
//  test15
//
//  Created by 胜皓唐 on 2020/7/2.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"

typedef int(^Test4Block)(int);

@interface ViewController ()

@property (nonatomic, copy) Test4Block block5;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    //========没有使用外部变量的使用==========
    void(^TestBlock)(void) = ^(void){
        NSLog(@"无参数，无返回值");
    };
    TestBlock();
    NSLog(@"无参数无返回值的block：%@",TestBlock);
    
    void(^Test2Block)(int t) = ^(int t){
        NSLog(@"有参数，无返回值%d", t);
    };
    Test2Block(2);
    NSLog(@"有参数，无返回值的block：%@", Test2Block);
    
    int(^Test3Block)(int t) = ^(int t){
        NSLog(@"有参数，有返回值%d", t);
        return t;
    };
    int result = Test3Block(2);
    NSLog(@"有参数，有返回值的block：%@---%d", Test3Block, result);
    
    Test4Block block4 = ^int(int t) {
        NSLog(@"typedef 有参数，有返回值%d", t);
        return t;
    };
    
    int result2 = block4(2);
    NSLog(@"typedef 有参数，有返回值的block：%@---%d", block4, result2);
    
    self.block5 = ^int(int t) {
        NSLog(@"typedef 属性 有参数，有返回值%d", t);
        return t;
    };
    
    int result3 = self.block5(2);
    NSLog(@"typedef 有参数，有返回值的block：%@---%d", self.block5, result3);
    
    
    
    
    //========使用外部变量的使用==========
    int i = 2;
    //复制外部变量到内部，捕获。只能读取，不能修改
    void(^Test6Block)(int t) = ^(int t) {
        NSLog(@"捕获到的%d", i);
    };
    i = 4;
    Test6Block(3);
    NSLog(@"使用外部变量的Block：%@",Test6Block);
    
    //使用__block可以修改外部变量
    __block int j = 3;
    void(^Test7Block)(void) = ^(void) {
        NSLog(@"捕获到的%d", j);
        j = 5;
        NSLog(@"修改后的值%d", j);
        
    };
    j = 4;
    Test7Block();
    
    NSLog(@"使用外部变量并且使用__block修饰外部变量：%@， %d", Test7Block, j);
    
    
    
}


@end
