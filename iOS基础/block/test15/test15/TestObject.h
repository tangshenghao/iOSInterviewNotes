//
//  TestObject.h
//  test15
//
//  Created by 胜皓唐 on 2020/7/5.
//  Copyright © 2020 tsh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^TestBlock)(void);

@interface TestObject : NSObject

@property (nonatomic, copy) TestBlock testBlock;

@end

NS_ASSUME_NONNULL_END
