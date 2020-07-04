//
//  ViewController.m
//  test15
//
//  Created by 胜皓唐 on 2020/7/2.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "TestObject.h"

typedef int(^Test4Block)(int t);

@interface ViewController ()

@property (nonatomic, copy) Test4Block block5;
@property (nonatomic, strong) TestObject *test;

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
    
    __block int k = 6;
    self.block5 = ^int(int t) {
        NSLog(@"typedef 属性 有参数，有返回值%d---%d", t, k);
        return t;
    };
    
//    int result3 = self.block5(2);
//    NSLog(@"typedef 有参数，有返回值的block：%@---%d", self.block5, result3);
    
    
    
    
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
    
    
    NSLog(@"class = %@, super Class = %@, base Class = %@", [Test7Block class], [[[Test7Block class] superclass] superclass], [[[[Test7Block class] superclass] superclass] superclass]);
    
    [self doSomeThing:^int(int t) {
        NSLog(@"block函数");
        return 4;
    }];
    
    Test4Block block9 = [self doSomeThing2:4];
    NSLog(@"result = %d", block9(2));
    
//    self.test = [[TestObject alloc] init];
//    self.test.testBlock = ^{
//        NSLog(@"%@",self.block5);
//    };
//    self.test.testBlock();
    
    
}

//作为参数调用
- (void)doSomeThing:(Test4Block)block {
    NSLog(@"调用了函数:%d", block(3));
}

//作为返回值调用
- (Test4Block)doSomeThing2:(int )t {
    Test4Block block = ^int(int x) {
        return x + t;
    };
    return block;
}

- (IBAction)testAction:(id)sender {
    self.block5(3);
}


@end
