//
//  TSHOperation.m
//  test19
//
//  Created by 胜皓唐 on 2020/7/10.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "TSHOperation.h"

@implementation TSHOperation


- (void)main {
    if (!self.isCancelled) {
        for (int i = 0; i < 2; i++) {
            [NSThread sleepForTimeInterval:2];
            NSLog(@"1---%@", [NSThread currentThread]);
        }
    }
}

@end
