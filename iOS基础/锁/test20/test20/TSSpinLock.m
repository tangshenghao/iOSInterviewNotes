//
//  TSSpinLock.m
//  test20
//
//  Created by 胜皓唐 on 2020/9/7.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TSSpinLock.h"

@interface TSSpinLock()

@property (nonatomic, assign) int flag;

@end

@implementation TSSpinLock

- (instancetype)init {
    self = [super init];
    if (self) {
        _flag = 0;
    }
    return self;
}

- (void)lock {
    while ([self testLockWithTag:1]) {

    }
}

- (int)testLockWithTag:(int)tag {
    
    int oldValue = _flag;
    
    _flag = tag;
    
    return oldValue;
}

- (void)unlock {
    _flag = 0;
}

@end
