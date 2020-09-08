//
//  TSSpinLock.h
//  test20
//
//  Created by 胜皓唐 on 2020/9/7.
//  Copyright © 2020 tsh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSSpinLock : NSObject

- (void)lock;

- (void)unlock;

@end

NS_ASSUME_NONNULL_END
