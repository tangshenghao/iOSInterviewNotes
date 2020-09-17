//
//  LargeImageView.m
//  test23
//
//  Created by 胜皓唐 on 2020/9/17.
//  Copyright © 2020 tsh. All rights reserved.
//

#import "LargeImageView.h"

@interface LargeImageView() {
    long long tiledCount;
    UIImage *originImage;
    CGRect imageRect;
    CGFloat imageScale_w;
    CGFloat imageScale_h;
}

@end

@implementation LargeImageView

- (void)setImageName:(NSString *)imageName {
    [self lg_setImage:[UIImage imageNamed:imageName]];
}

- (void)lg_setImage:(UIImage *)image {
    if (tiledCount == 0) tiledCount = 16;
    originImage = image;
    [self setBackgroundColor:[UIColor whiteColor]];
    imageRect = CGRectMake(0.0f,
                           0.0f,
                           CGImageGetWidth(originImage.CGImage),
                           CGImageGetHeight(originImage.CGImage));
    imageScale_w = self.frame.size.width/imageRect.size.width;
    imageScale_h = self.frame.size.height/imageRect.size.height;
    CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
    
    int scale = (int)MAX(1/imageScale_w, 1/imageScale_h);
    
    int lev = ceil(scale);
    tiledLayer.levelsOfDetail = 1;
    tiledLayer.levelsOfDetailBias = lev;
    
    if(tiledCount > 0){
        NSInteger tileSizeScale = sqrt(tiledCount)/2;
        CGSize tileSize = self.bounds.size;
        tileSize.width /=tileSizeScale;
        tileSize.height /=tileSizeScale;
        tiledLayer.tileSize = tileSize;
    }
}

+ (Class)layerClass {
    return [CATiledLayer class];
}

- (void)drawRect:(CGRect)rect {
    @autoreleasepool{
        CGRect imageCutRect = CGRectMake(rect.origin.x / imageScale_w,
                                         rect.origin.y / imageScale_h,
                                         rect.size.width / imageScale_w,
                                         rect.size.height / imageScale_h);
        CGImageRef imageRef = CGImageCreateWithImageInRect(originImage.CGImage, imageCutRect);
        UIImage *tileImage = [UIImage imageWithCGImage:imageRef];
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        [tileImage drawInRect:rect];
        CGImageRelease(imageRef);
        UIGraphicsPopContext();
    }
}
@end
