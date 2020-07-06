//
//  TestObject.h
//  test16
//
//  Created by 胜皓唐 on 2020/7/6.
//  Copyright © 2020 tsh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestObject : NSObject {
    NSString *_secondString;
}

@property (nonatomic, strong) TestObject *test2;

@property (nonatomic, copy) NSString *name;

@property (nonatomic, assign) int age;

- (void)testSetName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
