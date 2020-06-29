//
//  NSObject+JSONExtension.h
//  test13
//
//  Created by 胜皓唐 on 2020/6/30.
//  Copyright © 2020 tsh. All rights reserved.
//




#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (JSONExtension)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
