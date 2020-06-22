//
//  TestObject.m
//  test11
//
//  Created by 胜皓唐 on 2020/6/23.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TestObject.h"

@implementation TestObject

- (void)dealloc {
    [super dealloc];
    NSLog(@"TestObject dealloc");
}

- (void)printSomeThing {
    NSLog(@"print Some Thing");
}

@end
