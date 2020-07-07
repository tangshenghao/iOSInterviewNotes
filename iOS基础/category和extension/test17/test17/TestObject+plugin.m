//
//  TestObject+plugin.m
//  test17
//
//  Created by 胜皓唐 on 2020/7/7.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TestObject+plugin.h"
#import <objc/runtime.h>

@implementation TestObject (plugin)

- (void)testLog2 {
    NSLog(@"testLog2, %@", self.testString);
}

- (void)testLog4 {
    self.testString = @"111";
}

- (NSString *)testString {
    return objc_getAssociatedObject(self, @"testString");
}

- (void)setTestString:(NSString *)testString {
    return objc_setAssociatedObject(self, @"testString", testString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
