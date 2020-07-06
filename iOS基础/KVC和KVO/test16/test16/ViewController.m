//
//  ViewController.m
//  test16
//
//  Created by 胜皓唐 on 2020/7/6.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "ViewController.h"
#import "TestObject.h"
#import <objc/objc.h>
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //KVC
    TestObject *test = [[TestObject alloc] init];
    [test setValue:[[TestObject alloc] init] forKey:@"test2"];
    [test setValue:@"aaa" forKey:@"name"];
    [test setValue:@2 forKeyPath:@"age"];
    [test setValue:@"bbb" forKeyPath:@"test2.name"];
    [test setValue:@"ccc" forKeyPath:@"secondString"];
    NSLog(@"1-%@",test.name);
    NSLog(@"2-%d",test.age);
    NSLog(@"3-%@",test.test2.name);
    NSLog(@"4-%@",[test valueForKey:@"secondString"]);
    
    TestObject *test3 = [[TestObject alloc] init];
    test3.age = 13;
    TestObject *test4 = [[TestObject alloc] init];
    test4.age = 14;
    TestObject *test5 = [[TestObject alloc] init];
    test5.age = 15;
    TestObject *test6 = [[TestObject alloc] init];
    test6.age = 15;
    
    NSArray *array = @[test3, test4, test5, test6];
    NSNumber *number = [array valueForKeyPath:@"@min.age"];
    NSLog(@"5-%f",number.floatValue);
    
    NSArray *tempArray = [array valueForKeyPath:@"@distinctUnionOfObjects.age"];
    NSLog(@"6-%@",tempArray);
    
    NSDictionary *tempDictionay = @{@"name":@"xxxx", @"age":@18};
    [test6 setValuesForKeysWithDictionary:tempDictionay];
    NSLog(@"7-%@, %d", test6.name, test6.age);
    
    NSDictionary *tempDictionary2 = [test6 dictionaryWithValuesForKeys:@[@"name", @"age"]];
    NSLog(@"8-%@",tempDictionary2);
    
    TestObject *test7 = [[TestObject alloc] init];
    [test7 addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
//    test7.name = @"asdasd";
//    test7.name = @"qweqwe";

    [test7 setValue:@"aaaa" forKey:@"name"];
    
    [test7 testSetName:@"ssdasd"];
    
    NSLog(@"object:%@ - class:%@ - isaClass:%@", test7, [test7 class], [NSString stringWithUTF8String:object_getClassName(test7)]);
    
    Class class = object_getClass(test7);
    
    unsigned int count;
    Method *methodList = class_copyMethodList(class, &count);
    for (int i = 0; i < count; i++) {
        SEL methodSEL = method_getName(methodList[i]);
        const char *name = sel_getName(methodSEL);
        NSLog(@"method name:%@", [NSString stringWithUTF8String:name]);
        
    }
    
    Class superClass = class_getSuperclass(class);
    const char *superClassName = class_getName(superClass);
    NSLog(@"superClassName : %@ ", [NSString stringWithUTF8String:superClassName]);
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"object = %@, keyPath = %@, change = %@",object, keyPath, change);
}


@end
