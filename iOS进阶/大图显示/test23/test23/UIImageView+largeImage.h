//
//  UIImageView+largeImage.h
//  test23
//
//  Created by 胜皓唐 on 2020/9/17.
//  Copyright © 2020 tsh. All rights reserved.
//




#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (largeImage)

- (void)setLargeImage:(UIImage *)image;

- (void)setLargeTiledImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
