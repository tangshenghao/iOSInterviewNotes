//
//  TestObject.m
//  test17
//
//  Created by 胜皓唐 on 2020/7/7.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TestObject.h"
#import "TestObject+extension.h"

@interface TestObject()

//@property (nonatomic, copy) NSString *testString;

- (void)testLog3;

@end

@implementation TestObject

- (void)testLog {
    NSLog(@"testLog");
}

- (void)testLog3 {
    NSLog(@"testLog3");
}

@end
