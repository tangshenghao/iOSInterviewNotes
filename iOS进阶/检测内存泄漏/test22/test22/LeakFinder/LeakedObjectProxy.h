//
//  LeakedObjectProxy.h
//  test22
//
//  Created by 胜皓唐 on 2020/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LeakedObjectProxy : NSObject

+ (BOOL)isAnyObjectLeakedAtPtrs:(NSSet *)ptrs;
+ (void)addLeakedObject:(id)object;

@end

NS_ASSUME_NONNULL_END
