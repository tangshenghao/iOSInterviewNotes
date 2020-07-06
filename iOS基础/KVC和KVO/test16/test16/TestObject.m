//
//  TestObject.m
//  test16
//
//  Created by 胜皓唐 on 2020/7/6.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TestObject.h"

@implementation TestObject

- (void)_setSecondString:(NSString *)secondString {
    _secondString = secondString;
}

- (void)testSetName:(NSString *)name {
    _name = name;
}

//- (void)setName:(NSString *)name {
//    [self willChangeValueForKey:@"name"];
//    _name = name;
//    [self didChangeValueForKey:@"name"];
//}
//
//+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
//    if ([key isEqualToString:@"name"]) {
//        return NO;
//    }
//    return [super automaticallyNotifiesObserversForKey:key];
//}
@end
