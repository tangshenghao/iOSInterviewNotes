//
//  TestObject+plugin.h
//  test17
//
//  Created by 胜皓唐 on 2020/7/7.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TestObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface TestObject (plugin)

@property (nonatomic, copy) NSString *testString;

- (void)testLog2;

- (void)testLog4;

@end

NS_ASSUME_NONNULL_END
