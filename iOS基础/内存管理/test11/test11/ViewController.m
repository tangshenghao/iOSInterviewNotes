//
//  ViewController.m
//  test11
//
//  Created by 胜皓唐 on 2020/6/23.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "TestObject.h"

@interface ViewController ()

@property (nonatomic, retain) TestObject *testProperty;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //存在栈中
    int testInt = 2;
    float testFloat = 3.0;
    
    NSLog(@"值类型的指针地址 %p %p", &testInt, &testFloat);
    
    //存在堆中
    TestObject *object = [[TestObject alloc] init];
    
    NSLog(@"引用计数 = %lu， 对象的内存 = %p，指针的地址 = %p", (unsigned long)object.retainCount, object, &object);
    
    self.testProperty = object;
    
    NSLog(@"引用计数 = %lu， 对象的内存 = %p，指针的地址 = %p, 属性指针的地址 = %p", (unsigned long)object.retainCount, self.testProperty, &object, &_testProperty);
    
    [object release];
    
    NSLog(@"引用计数 = %lu， 对象的内存 = %p，指针的地址 = %p, 属性指针的地址 = %p", (unsigned long)object.retainCount, self.testProperty, &object, &_testProperty);
    [object printSomeThing];
    [object release];
    
    
    
    // 销毁之后执行会崩溃 关联的内存已经销毁，去执行对应的方法会崩溃
//    [object printSomeThing];
    
    
    
    
}


@end
