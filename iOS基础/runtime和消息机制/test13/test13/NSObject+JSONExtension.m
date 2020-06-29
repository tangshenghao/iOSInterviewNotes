//
//  NSObject+JSONExtension.m
//  test13
//
//  Created by 胜皓唐 on 2020/6/30.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "NSObject+JSONExtension.h"

#import <objc/runtime.h>


@implementation NSObject (JSONExtension)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    
    self = [self init];
    
    if (self) {
        unsigned int count;
        objc_property_t *propertyList = class_copyPropertyList([self class], &count);
        
        for (int i = 0; i < count; i++) {
            // 获取属性列表
            const char *propertyName = property_getName(propertyList[i]);
            
            NSString *name = [NSString stringWithUTF8String:propertyName];
            id value = [dictionary objectForKey:name];
            if (value) {
                [self setValue:value forKey:name];
            }
        }
        free(propertyList);
    }
    
    return self;
}

@end
