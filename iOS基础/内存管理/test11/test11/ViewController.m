//
//  ViewController.m
//  test11
//
//  Created by 胜皓唐 on 2020/6/23.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "TestObject.h"
#import "SecondViewController.h"

@interface ViewController ()

@property (nonatomic, retain) TestObject *testProperty;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    //存在栈中
//    int testInt = 2;
//    float testFloat = 3.0;
//
//    NSLog(@"值类型的指针地址 %p %p", &testInt, &testFloat);
//
//    //存在堆中
//    TestObject *object = [[TestObject alloc] init];
//
//    NSLog(@"引用计数 = %lu， 对象的内存 = %p，指针的地址 = %p", (unsigned long)object.retainCount, object, &object);
//
//    self.testProperty = object;
//
//    NSLog(@"引用计数 = %lu， 对象的内存 = %p，指针的地址 = %p, 属性指针的地址 = %p", (unsigned long)object.retainCount, self.testProperty, &object, &_testProperty);
//
//    [object release];
//
//    NSLog(@"引用计数 = %lu， 对象的内存 = %p，指针的地址 = %p, 属性指针的地址 = %p", (unsigned long)object.retainCount, self.testProperty, &object, &_testProperty);
//    [object printSomeThing];
//    [object release];
//
//
//
//    // 销毁之后执行会崩溃 关联的内存已经销毁，去执行对应的方法会崩溃
////    [object printSomeThing];
//
//    //自己生成自己持有
//    TestObject *object2 = [[TestObject alloc] init];
//    TestObject *object3 = [TestObject new];
//    NSLog(@"引用计数1 = %lu，引用计数2 = %lu， 对象的内存 = %p，指针1的地址 = %p, 指针2的地址 = %p,", (unsigned long)object2.retainCount,(unsigned long)object3.retainCount, object3, &object2, &object3);
//
//    //非自己生成也能持有
//    NSArray *array = [NSMutableArray arrayWithCapacity:2];
////    [array retain];
//
//    //不需要使用时释放
//    [object2 release];
//
//    //非自己持有的对象无法释放
//    NSLog(@"array retainCount = %lu", array.retainCount);
//    [array release];
//    //释放之后已经不持有，再释放就崩溃
////    [array release];
    
    TestObject *object4 = [[TestObject alloc] init];
    [object4 autorelease];
    NSLog(@"object4 retainCount = %lu", object4.retainCount);
}
- (IBAction)toNextVC:(id)sender {
    SecondViewController *vc = [[SecondViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
