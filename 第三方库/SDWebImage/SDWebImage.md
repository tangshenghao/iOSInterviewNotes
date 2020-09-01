## SDWebImage

### 1 SDWebImage简介

SDWebImage实现了异步下载图片并且支持缓存的功能。框架的接口调用非常简洁，是iOS开发工程师基本都会使用的第三方框架。

该篇分析的源码版本是5.8.1。是写这篇文章时的最新版本。相比4.x。5.x加了很多代码和文件，可能分析得不是特别细。

整体的流程图如下：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E7%AC%AC%E4%B8%89%E6%96%B9%E5%BA%93/SDWebImage/SDWebImage%E6%B5%81%E7%A8%8B.jpg?raw=true)

最简单的调用方式：

```
[imageView sd_setImageWithURL:[NSURL URLWithString:@"https://www.baidu.com/img/flexible/logo/pc/result@2.png"]];
```

直接传递图片地址即可实现异步下载和显示的功能。

框架的核心是SDWebImageManager，在外部有UIImageView+WebCache和UIbutton+WebCache为图片和按钮提供接口。内部通过SDWebImageManager负责处理和协调SDWebImageDownloader进行下载任务和SDWebImageCache负责关于缓存的相关任务。

<br />

#### 1.1 UIKit层

UIKit层是通过给定UIImageView、UIButton的分类来实现具体显示图片的功能接口。同时还给了SDAnimatedImageView也实现了分类接口。SDAnimatedImageView是5.0版本之后框架提供的适用于动图渲染的View，尤其是大型动画的渲染，对内存做了优化。

先通过常用的UIImageView和UIButton的分类来分析UIKit层的代码实现。

**UIImageView+Cache.h**

该类提供了设置图片URL、placeholder、数据下载进度回调以及显示完成回调等接口。

```

- (void)sd_setImageWithURL:(nullable NSURL *)url NS_REFINED_FOR_SWIFT;


- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder NS_REFINED_FOR_SWIFT;


- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options NS_REFINED_FOR_SWIFT;


- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                   context:(nullable SDWebImageContext *)context;


- (void)sd_setImageWithURL:(nullable NSURL *)url
                 completed:(nullable SDExternalCompletionBlock)completedBlock;


- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                 completed:(nullable SDExternalCompletionBlock)completedBlock NS_REFINED_FOR_SWIFT;


- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                 completed:(nullable SDExternalCompletionBlock)completedBlock;


- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                  progress:(nullable SDImageLoaderProgressBlock)progressBlock
                 completed:(nullable SDExternalCompletionBlock)completedBlock;


- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                   context:(nullable SDWebImageContext *)context
                  progress:(nullable SDImageLoaderProgressBlock)progressBlock
                 completed:(nullable SDExternalCompletionBlock)completedBlock;
```

<br />

**UIImageView+Cache.m**

通过实现文件看，实际上所有的接口最终都是指向sd_setImageWithURL:placeholderImage:options:context:方法。方法里面的实现是调用了sd_internalSetImageWithURL:的方法，该方法是在UIView+WebCache中实现的。

```
- (void)sd_setImageWithURL:(nullable NSURL *)url {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options context:(nullable SDWebImageContext *)context {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options context:context progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options progress:(nullable SDImageLoaderProgressBlock)progressBlock completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                   context:(nullable SDWebImageContext *)context
                  progress:(nullable SDImageLoaderProgressBlock)progressBlock
                 completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:context
                       setImageBlock:nil
                            progress:progressBlock
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}
```

<br />

**UIButton+WebCache**

UIButton+WebCache内的实现与UIImageView+WebCache的实现方式基本一致，只是多了用字典来存储每个button的state的对应的URL等数据。然后分别实现了设置UIButton的image和backgroundImage的两个方式的接口。

<br />

**UIView+WebCache**

上述两个分类的实现最终都会到该分类中实现。

具体的实现代码如下：

省略了部分代码

```
- (void)sd_internalSetImageWithURL:(nullable NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholder
                           options:(SDWebImageOptions)options
                           context:(nullable SDWebImageContext *)context
                     setImageBlock:(nullable SDSetImageBlock)setImageBlock
                          progress:(nullable SDImageLoaderProgressBlock)progressBlock
                         completed:(nullable SDInternalCompletionBlock)completedBlock {
    
    //省略
    .......
    
    // 此处是获取valid key
    NSString *validOperationKey = context[SDWebImageContextSetImageOperationKey];
    if (!validOperationKey) {
        // pass through the operation key to downstream, which can used for tracing operation or image view class
        validOperationKey = NSStringFromClass([self class]);
        SDWebImageMutableContext *mutableContext = [context mutableCopy];
        mutableContext[SDWebImageContextSetImageOperationKey] = validOperationKey;
        context = [mutableContext copy];
    }
    self.sd_latestOperationKey = validOperationKey;
    
    // 确保没有正在进行的异步下载操作
    [self sd_cancelImageLoadOperationWithKey:validOperationKey];
    self.sd_imageURL = url;
    
    // 设置临时占位图
    if (!(options & SDWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            [self sd_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:setImageBlock cacheType:SDImageCacheTypeNone imageURL:url];
        });
    }
    
    //如果url存在
    if (url) {
   
        // reset the progress 重置进度属性
        NSProgress *imageProgress = objc_getAssociatedObject(self, @selector(sd_imageProgress));
        if (imageProgress) {
            imageProgress.totalUnitCount = 0;
            imageProgress.completedUnitCount = 0;
        }
        
        // 开启Indicator 显示状态栏的加载中
#if SD_UIKIT || SD_MAC
        // check and start image indicator
        [self sd_startImageIndicator];
        id<SDWebImageIndicator> imageIndicator = self.sd_imageIndicator;
#endif
				// 获取核心管理类manager
        SDWebImageManager *manager = context[SDWebImageContextCustomManager];
        if (!manager) {
            manager = [SDWebImageManager sharedManager];
        } else {
            // remove this manager to avoid retain cycle (manger -> loader -> operation -> context -> manager)
            SDWebImageMutableContext *mutableContext = [context mutableCopy];
            mutableContext[SDWebImageContextCustomManager] = nil;
            context = [mutableContext copy];
        }
        
        // 定义进度block 省略
        ......
        
        // 进行下载操作
        @weakify(self);
        id <SDWebImageOperation> operation = [manager loadImageWithURL:url options:options context:context progress:combinedProgressBlock completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            @strongify(self);
            if (!self) { return; }
            // if the progress not been updated, mark it to complete state
            if (imageProgress && finished && !error && imageProgress.totalUnitCount == 0 && imageProgress.completedUnitCount == 0) {
                imageProgress.totalUnitCount = SDWebImageProgressUnitCountUnknown;
                imageProgress.completedUnitCount = SDWebImageProgressUnitCountUnknown;
            }
            
#if SD_UIKIT || SD_MAC
            // check and stop image indicator
            if (finished) {
                [self sd_stopImageIndicator];
            }
#endif
            
            BOOL shouldCallCompletedBlock = finished || (options & SDWebImageAvoidAutoSetImage);
            BOOL shouldNotSetImage = ((image && (options & SDWebImageAvoidAutoSetImage)) ||
                                      (!image && !(options & SDWebImageDelayPlaceholder)));
            SDWebImageNoParamsBlock callCompletedBlockClojure = ^{
                if (!self) { return; }
                if (!shouldNotSetImage) {
                    [self sd_setNeedsLayout];
                }
                if (completedBlock && shouldCallCompletedBlock) {
                    completedBlock(image, data, error, cacheType, finished, url);
                }
            };
            
            // case 1a: we got an image, but the SDWebImageAvoidAutoSetImage flag is set
            // OR
            // case 1b: we got no image and the SDWebImageDelayPlaceholder is not set
            if (shouldNotSetImage) {
                dispatch_main_async_safe(callCompletedBlockClojure);
                return;
            }
            
            // 设置图片 省略
            .....
            
            dispatch_main_async_safe(^{
								// 调用设置图片
                [self sd_setImage:targetImage imageData:targetData basedOnClassOrViaCustomSetImageBlock:setImageBlock transition:transition cacheType:cacheType imageURL:imageURL];

                callCompletedBlockClojure();
            });
        }];
        [self sd_setImageLoadOperation:operation forKey:validOperationKey];
    } else {
				// 返回异常error回调
    }
}

// 设置图片
- (void)sd_setImage:(UIImage *)image imageData:(NSData *)imageData basedOnClassOrViaCustomSetImageBlock:(SDSetImageBlock)setImageBlock transition:(SDWebImageTransition *)transition cacheType:(SDImageCacheType)cacheType imageURL:(NSURL *)imageURL {
    UIView *view = self;
    SDSetImageBlock finalSetImageBlock;
    // 如果外部实现了setImageBlock则直接返回
    if (setImageBlock) {
        finalSetImageBlock = setImageBlock;
    } else if ([view isKindOfClass:[UIImageView class]]) {
    // 如果没实现，则判断调用的类是不是UIImageView或者UIButton，并直接对image进行赋值
        UIImageView *imageView = (UIImageView *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, SDImageCacheType setCacheType, NSURL *setImageURL) {
            imageView.image = setImage;
        };
    }
    else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, SDImageCacheType setCacheType, NSURL *setImageURL) {
            [button setImage:setImage forState:UIControlStateNormal];
        };
    }


    // 设置图片转场效果
    if (transition) {
				// 省略
    } else {
        if (finalSetImageBlock) {
            finalSetImageBlock(image, imageData, cacheType, imageURL);
        }
    }
}
```

其中sd_setImageLoadOperation这个操作，是对应的一个将operation对象存储到一个MapTable中，这个是有一个专门的UIView+WebCacheOperation分类来实现的，该类专门管理了operation MapTable的插入、获取、取消和移除操作。

以上就是UIKit层的内容。

<br />

#### 1.2 工具层

上节说到SDWebImageManager负责处理和协调SDWebImageDownloader进行下载任务和SDWebImageCache负责关于缓存的相关任务。

先看看SDWebImageManager这个类。最主要的就是在UIView+WebCache中调用的下载图片接口，实现代码如下：

```
- (SDWebImageCombinedOperation *)loadImageWithURL:(nullable NSURL *)url
                                          options:(SDWebImageOptions)options
                                          context:(nullable SDWebImageContext *)context
                                         progress:(nullable SDImageLoaderProgressBlock)progressBlock
                                        completed:(nonnull SDInternalCompletionBlock)completedBlock {
    // Invoking this method without a completedBlock is pointless
    NSAssert(completedBlock != nil, @"If you mean to prefetch the image, use -[SDWebImagePrefetcher prefetchURLs] instead");

    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, Xcode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
		
    SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new];
    operation.manager = self;

    BOOL isFailedUrl = NO;
    if (url) {
        SD_LOCK(self.failedURLsLock);
        isFailedUrl = [self.failedURLs containsObject:url];
        SD_UNLOCK(self.failedURLsLock);
    }

    if (url.absoluteString.length == 0 || (!(options & SDWebImageRetryFailed) && isFailedUrl)) {
        NSString *description = isFailedUrl ? @"Image url is blacklisted" : @"Image url is nil";
        NSInteger code = isFailedUrl ? SDWebImageErrorBlackListed : SDWebImageErrorInvalidURL;
        [self callCompletionBlockForOperation:operation completion:completedBlock error:[NSError errorWithDomain:SDWebImageErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : description}] url:url];
        return operation;
    }

    SD_LOCK(self.runningOperationsLock);
    [self.runningOperations addObject:operation];
    SD_UNLOCK(self.runningOperationsLock);
    
    // Preprocess the options and context arg to decide the final the result for manager
    SDWebImageOptionsResult *result = [self processedResultForURL:url options:options context:context];
    // 前面都是判断用 此处调用从缓存取图片
    // Start the entry to load image from cache
    [self callCacheProcessForOperation:operation url:url options:result.options context:result.context progress:progressBlock completed:completedBlock];

    return operation;
}


// Query normal cache process
- (void)callCacheProcessForOperation:(nonnull SDWebImageCombinedOperation *)operation
                                 url:(nonnull NSURL *)url
                             options:(SDWebImageOptions)options
                             context:(nullable SDWebImageContext *)context
                            progress:(nullable SDImageLoaderProgressBlock)progressBlock
                           completed:(nullable SDInternalCompletionBlock)completedBlock {
    // Grab the image cache to use
    id<SDImageCache> imageCache;
    if ([context[SDWebImageContextImageCache] conformsToProtocol:@protocol(SDImageCache)]) {
        imageCache = context[SDWebImageContextImageCache];
    } else {
        imageCache = self.imageCache;
    }
    
    // Get the query cache type
    SDImageCacheType queryCacheType = SDImageCacheTypeAll;
    if (context[SDWebImageContextQueryCacheType]) {
        queryCacheType = [context[SDWebImageContextQueryCacheType] integerValue];
    }
    
    // Check whether we should query cache
    BOOL shouldQueryCache = !SD_OPTIONS_CONTAINS(options, SDWebImageFromLoaderOnly);
    if (shouldQueryCache) {
    
    		//key是通过url生成的 里面有条件过滤或者是缩放和转换效果会影响到key 通常没有这些条件会是url地址作为key
        NSString *key = [self cacheKeyForURL:url context:context];
        @weakify(operation);
    		// 执行取缓存的操作
        operation.cacheOperation = [imageCache queryImageForKey:key options:options context:context cacheType:queryCacheType completion:^(UIImage * _Nullable cachedImage, NSData * _Nullable cachedData, SDImageCacheType cacheType) {
            @strongify(operation);
            if (!operation || operation.isCancelled) {
                // Image combined operation cancelled by user
                [self callCompletionBlockForOperation:operation completion:completedBlock error:[NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorCancelled userInfo:@{NSLocalizedDescriptionKey : @"Operation cancelled by user during querying the cache"}] url:url];
                [self safelyRemoveOperationFromRunning:operation];
                return;
            } else if (context[SDWebImageContextImageTransformer] && !cachedImage) {
                // Have a chance to query original cache instead of downloading
                [self callOriginalCacheProcessForOperation:operation url:url options:options context:context progress:progressBlock completed:completedBlock];
                return;
            }
            // 继续上述判断后也会执行下载操作 区别只是此处是从缓存获取到了image
            // Continue download process
            [self callDownloadProcessForOperation:operation url:url options:options context:context cachedImage:cachedImage cachedData:cachedData cacheType:cacheType progress:progressBlock completed:completedBlock];
        }];
    } else {
    		// 没有找到缓存则去执行下载操作
        // Continue download process
        [self callDownloadProcessForOperation:operation url:url options:options context:context cachedImage:nil cachedData:nil cacheType:SDImageCacheTypeNone progress:progressBlock completed:completedBlock];
    }
}

// 下载流程
// Download process
- (void)callDownloadProcessForOperation:(nonnull SDWebImageCombinedOperation *)operation
                                    url:(nonnull NSURL *)url
                                options:(SDWebImageOptions)options
                                context:(SDWebImageContext *)context
                            cachedImage:(nullable UIImage *)cachedImage
                             cachedData:(nullable NSData *)cachedData
                              cacheType:(SDImageCacheType)cacheType
                               progress:(nullable SDImageLoaderProgressBlock)progressBlock
                              completed:(nullable SDInternalCompletionBlock)completedBlock {
    // Grab the image loader to use
    // 获取下载器的实例
    id<SDImageLoader> imageLoader;
    if ([context[SDWebImageContextImageLoader] conformsToProtocol:@protocol(SDImageLoader)]) {
        imageLoader = context[SDWebImageContextImageLoader];
    } else {
        imageLoader = self.imageLoader;
    }
    
    // Check whether we should download image from network
    BOOL shouldDownload = !SD_OPTIONS_CONTAINS(options, SDWebImageFromCacheOnly);
    shouldDownload &= (!cachedImage || options & SDWebImageRefreshCached);
    shouldDownload &= (![self.delegate respondsToSelector:@selector(imageManager:shouldDownloadImageForURL:)] || [self.delegate imageManager:self shouldDownloadImageForURL:url]);
    shouldDownload &= [imageLoader canRequestImageForURL:url];
    if (shouldDownload) {
    
        if (cachedImage && options & SDWebImageRefreshCached) {
            // If image was found in the cache but SDWebImageRefreshCached is provided, notify about the cached image
            // AND try to re-download it in order to let a chance to NSURLCache to refresh it from server.
            [self callCompletionBlockForOperation:operation completion:completedBlock image:cachedImage data:cachedData error:nil cacheType:cacheType finished:YES url:url];
            // Pass the cached image to the image loader. The image loader should check whether the remote image is equal to the cached image.
            SDWebImageMutableContext *mutableContext;
            if (context) {
                mutableContext = [context mutableCopy];
            } else {
                mutableContext = [NSMutableDictionary dictionary];
            }
            mutableContext[SDWebImageContextLoaderCachedImage] = cachedImage;
            context = [mutableContext copy];
        }
        
        //执行下载操作
        @weakify(operation);
        operation.loaderOperation = [imageLoader requestImageWithURL:url options:options context:context progress:progressBlock completed:^(UIImage *downloadedImage, NSData *downloadedData, NSError *error, BOOL finished) {
            @strongify(operation);
            if (!operation || operation.isCancelled) {
                // Image combined operation cancelled by user
                [self callCompletionBlockForOperation:operation completion:completedBlock error:[NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorCancelled userInfo:@{NSLocalizedDescriptionKey : @"Operation cancelled by user during sending the request"}] url:url];
            } else if (cachedImage && options & SDWebImageRefreshCached && [error.domain isEqualToString:SDWebImageErrorDomain] && error.code == SDWebImageErrorCacheNotModified) {
                // Image refresh hit the NSURLCache cache, do not call the completion block
            } else if ([error.domain isEqualToString:SDWebImageErrorDomain] && error.code == SDWebImageErrorCancelled) {
                // Download operation cancelled by user before sending the request, don't block failed URL
                [self callCompletionBlockForOperation:operation completion:completedBlock error:error url:url];
            } else if (error) {
                [self callCompletionBlockForOperation:operation completion:completedBlock error:error url:url];
                BOOL shouldBlockFailedURL = [self shouldBlockFailedURLWithURL:url error:error options:options context:context];
                
                if (shouldBlockFailedURL) {
                    SD_LOCK(self.failedURLsLock);
                    [self.failedURLs addObject:url];
                    SD_UNLOCK(self.failedURLsLock);
                }
            } else {
            // 上述都是错误的处理
                if ((options & SDWebImageRetryFailed)) {
                    SD_LOCK(self.failedURLsLock);
                    [self.failedURLs removeObject:url];
                    SD_UNLOCK(self.failedURLsLock);
                }
                // 将下载到的数据保存到缓存中
                // Continue store cache process
                [self callStoreCacheProcessForOperation:operation url:url options:options context:context downloadedImage:downloadedImage downloadedData:downloadedData finished:finished progress:progressBlock completed:completedBlock];
            }
            
            if (finished) {
                [self safelyRemoveOperationFromRunning:operation];
            }
        }];
    } else if (cachedImage) {
    // 如果不需要下载则将缓存的图片进行回调
        [self callCompletionBlockForOperation:operation completion:completedBlock image:cachedImage data:cachedData error:nil cacheType:cacheType finished:YES url:url];
        [self safelyRemoveOperationFromRunning:operation];
    } else {
        // Image not in cache and download disallowed by delegate
        [self callCompletionBlockForOperation:operation completion:completedBlock image:nil data:nil error:nil cacheType:SDImageCacheTypeNone finished:YES url:url];
        [self safelyRemoveOperationFromRunning:operation];
    }
}

// 存进缓存的操作
- (void)callStoreCacheProcessForOperation:(nonnull SDWebImageCombinedOperation *)operation
                                      url:(nonnull NSURL *)url
                                  options:(SDWebImageOptions)options
                                  context:(SDWebImageContext *)context
                          downloadedImage:(nullable UIImage *)downloadedImage
                           downloadedData:(nullable NSData *)downloadedData
                                 finished:(BOOL)finished
                                 progress:(nullable SDImageLoaderProgressBlock)progressBlock
                                completed:(nullable SDInternalCompletionBlock)completedBlock {
    // ....
    // 省略 一些类型的判断
    // ....
    NSString *key = [self cacheKeyForURL:url context:originContext];
    id<SDImageTransformer> transformer = context[SDWebImageContextImageTransformer];
    if (![transformer conformsToProtocol:@protocol(SDImageTransformer)]) {
        transformer = nil;
    }
    id<SDWebImageCacheSerializer> cacheSerializer = context[SDWebImageContextCacheSerializer];
    
    // ....
    // 省略 一些转换类型的判断
    // ....
    
    // if available, store original image to cache
    if (shouldCacheOriginal) {
        // normally use the store cache type, but if target image is transformed, use original store cache type instead
        SDImageCacheType targetStoreCacheType = shouldTransformImage ? originalStoreCacheType : storeCacheType;
        if (cacheSerializer && (targetStoreCacheType == SDImageCacheTypeDisk || targetStoreCacheType == SDImageCacheTypeAll)) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                @autoreleasepool {
                		// 在autoreleasepool中对图片数据进行转换成NSData 然后进行缓存
                    NSData *cacheData = [cacheSerializer cacheDataWithImage:downloadedImage originalData:downloadedData imageURL:url];
                    [self storeImage:downloadedImage imageData:cacheData forKey:key cacheType:targetStoreCacheType options:options context:context completion:^{
                        // Continue transform process 进行图片转换处理 并在内部进行图片的返回
                        [self callTransformProcessForOperation:operation url:url options:options context:context originalImage:downloadedImage originalData:downloadedData finished:finished progress:progressBlock completed:completedBlock];
                    }];
                }
            });
        } else {
            [self storeImage:downloadedImage imageData:downloadedData forKey:key cacheType:targetStoreCacheType options:options context:context completion:^{
                // Continue transform process 进行图片转换处理 并在内部进行图片的返回
                [self callTransformProcessForOperation:operation url:url options:options context:context originalImage:downloadedImage originalData:downloadedData finished:finished progress:progressBlock completed:completedBlock];
            }];
        }
    } else {
        // Continue transform process 进行图片转换处理 并在内部进行图片的返回
        [self callTransformProcessForOperation:operation url:url options:options context:context originalImage:downloadedImage originalData:downloadedData finished:finished progress:progressBlock completed:completedBlock];
    }
}
```

最后一个是在callTransformProcessForOperation中进行是否进行图片转换，如果有转换，则将转换后的数据存入缓存中并且返回UIKit层的回调，如果没有转换则直接返回回调。

上述就是SDWebImageManager对缓存和下载工具调度的处理。

<br />

##### 1.2.1 SDImageCache

在上小节的SDWebImageManager中，加载图片，最先会调用callCacheProcessForOperation，执行查询缓存的操作。对应的类是SDImageCache，来通过该类看一下缓存的流程。

该类定义的属性：

```
// 内存缓存的类 - 遵循<SDMemoryCache>协议的类，默认是SDMemoryCache，用来做缓存读写处理
@property (nonatomic, strong, readwrite, nonnull) id<SDMemoryCache> memoryCache;
// 磁盘缓存的类 - 遵循<SDDiskCache>协议的类，默认是SDDiskCache，用来做磁盘读写处理
@property (nonatomic, strong, readwrite, nonnull) id<SDDiskCache> diskCache;
// 缓存的配置参数的文件
@property (nonatomic, copy, readwrite, nonnull) SDImageCacheConfig *config;
// 磁盘存储的路径
@property (nonatomic, copy, readwrite, nonnull) NSString *diskCachePath;
// 唯一的读写队列 会在初始化时生成穿行的读写队列
@property (nonatomic, strong, nullable) dispatch_queue_t ioQueue;
```

实现文件中，较为重要的是读取流程，此时使用的是返回NSOperation来处理操作，使用NSOperation可以中途执行取消等操作以及存储到对应strong-weak的map中更方便的进行管理。

```
- (nullable NSOperation *)queryCacheOperationForKey:(nullable NSString *)key options:(SDImageCacheOptions)options context:(nullable SDWebImageContext *)context cacheType:(SDImageCacheType)queryCacheType done:(nullable SDImageCacheQueryCompletionBlock)doneBlock {
    //省略...部分判断逻辑
    
    // First check the in-memory cache... 现在缓存中检查是否存在图片
    UIImage *image;
    if (queryCacheType != SDImageCacheTypeDisk) {
        image = [self imageFromMemoryCacheForKey:key];
    }
    
    if (image) {
       	//省略 判断图片是否符合
    }
		
		// 判断是否只读取缓存图片
    BOOL shouldQueryMemoryOnly = (queryCacheType == SDImageCacheTypeMemory) || (image && !(options & SDImageCacheQueryMemoryData));
    if (shouldQueryMemoryOnly) {
        if (doneBlock) {
            doneBlock(image, nil, SDImageCacheTypeMemory);
        }
        return nil;
    }
    
    // Second check the disk cache... 检查硬盘中是否存在图片
    NSOperation *operation = [NSOperation new];
    // Check whether we need to synchronously query disk
    // 1. in-memory cache hit & memoryDataSync
    // 2. in-memory cache miss & diskDataSync
    BOOL shouldQueryDiskSync = ((image && options & SDImageCacheQueryMemoryDataSync) ||
                                (!image && options & SDImageCacheQueryDiskDataSync));
    void(^queryDiskBlock)(void) =  ^{
        if (operation.isCancelled) {
            if (doneBlock) {
                doneBlock(nil, nil, SDImageCacheTypeNone);
            }
            return;
        }
        
        @autoreleasepool {
        		// 获取磁盘中的图片数据
            NSData *diskData = [self diskImageDataBySearchingAllPathsForKey:key];
            UIImage *diskImage;
            SDImageCacheType cacheType = SDImageCacheTypeNone;
            if (image) {
                // the image is from in-memory cache, but need image data
                // 此处是上面缓存中的图片
                diskImage = image;
                cacheType = SDImageCacheTypeMemory;
            } else if (diskData) {
                cacheType = SDImageCacheTypeDisk;
                // decode image data only if in-memory cache missed
                // 如果缓存中没有找到图片，则将数据解码出image，然后存到缓存中
                diskImage = [self diskImageForKey:key data:diskData options:options context:context];
                if (diskImage && self.config.shouldCacheImagesInMemory) {
                    NSUInteger cost = diskImage.sd_memoryCost;
                    [self.memoryCache setObject:diskImage forKey:key cost:cost];
                }
            }
            
            if (doneBlock) {
                if (shouldQueryDiskSync) {
                    doneBlock(diskImage, diskData, cacheType);
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        doneBlock(diskImage, diskData, cacheType);
                    });
                }
            }
        }
    };
    
    // Query in ioQueue to keep IO-safe
    if (shouldQueryDiskSync) {
        dispatch_sync(self.ioQueue, queryDiskBlock);
    } else {
        dispatch_async(self.ioQueue, queryDiskBlock);
    }
    
    return operation;
}
```

在退到后台时，该类会申请一小段时间的后台任务来执行删除已经超时缓存的处理

```
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (!self.config.shouldRemoveExpiredDataWhenEnterBackground) {
        return;
    }
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    // Start the long-running task and return immediately.
    [self deleteOldFilesWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}
```

其中相别于旧版的处理缓存和磁盘的两个默认的类SDMemoryCache和SDDiskCache。

**SDMemoryCache**

SDMemoryCache是NSCache的子类，说明SDWebImage使用的是系统的NSCahce类来处理缓存，同时定义了SDMemoryCache的协议，将NSCache中的方法在协议中定义，可以实现自定义的类实现代理方法来管理缓存。

其中除了系统的NSCache的功能外，该类内部还通过弱引用的NSMapTable来做双重缓存的处理，在保存等操作中也会在NSMapTable中进行同样的操作。

```
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g {
    [super setObject:obj forKey:key cost:g];
    // 判断有没有使用弱引用内存 默认是yes
    if (!self.config.shouldUseWeakMemoryCache) {
        return;
    }
    if (key && obj) {
        // Store weak cache
        SD_LOCK(self.weakCacheLock);
        [self.weakCache setObject:obj forKey:key];
        SD_UNLOCK(self.weakCacheLock);
    }
}
```

采用NSMapTable是优化了，系统的NSCache会在某些情况下自动对缓存进行清除，而需要重新获取磁盘或者去网络重新下载，引起图片闪烁等问题。

**SDDiskCache**

SDDiskCache是用于对磁盘缓存文件进行处理的类，也是定义了SDDiskCache的协议，可以实现自定义的类来管理。实现文件内主要是通过NSFileManager对磁盘进行处理。同时在进入后台或者终止时去检查是否有过期的缓存文件，默认过期是1个星期。

<br />

##### 1.2.2 SDWebImageDownloader

接着看SDWebImageDownloader，该类负责处理图片下载。在头文件中定义了名为SDImageLoader的分类并遵循了SDImageLoader协议，因为在新版中SDWebImageManager中，是可以采用自定义的类来实现对应的下载功能，但是前提是需要遵循SDImageLoader协议。

其中该类最重要的就是下载方法downloadImageWithURL

```
- (nullable SDWebImageDownloadToken *)downloadImageWithURL:(nullable NSURL *)url
                                                   options:(SDWebImageDownloaderOptions)options
                                                   context:(nullable SDWebImageContext *)context
                                                  progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                                 completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock {
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data. 判断是否为空 返回错误
    if (url == nil) {
        if (completedBlock) {
            NSError *error = [NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorInvalidURL userInfo:@{NSLocalizedDescriptionKey : @"Image url is nil"}];
            completedBlock(nil, nil, error, YES);
        }
        return nil;
    }
    
    SD_LOCK(self.operationsLock);
    id downloadOperationCancelToken;
    NSOperation<SDWebImageDownloaderOperation> *operation = [self.URLOperations objectForKey:url];
    // There is a case that the operation may be marked as finished or cancelled, but not been removed from `self.URLOperations`.  省略 判断操作是否被中断或完成
    if (!operation || operation.isFinished || operation.isCancelled) {
        // 生成下载的operation
    		operation = [self createDownloaderOperationWithUrl:url options:options context:context];
    		// 省略异常判断和成功回调
    		[self.downloadQueue addOperation:operation];
    } else {
        // 省略存在operation的处理操作
    }
    SD_UNLOCK(self.operationsLock);
    
    SDWebImageDownloadToken *token = [[SDWebImageDownloadToken alloc] initWithDownloadOperation:operation];
    token.url = url;
    token.request = operation.request;
    token.downloadOperationCancelToken = downloadOperationCancelToken;
    
    return token;
}
// 创建下载操作
- (nullable NSOperation<SDWebImageDownloaderOperation> *)createDownloaderOperationWithUrl:(nonnull NSURL *)url
                                                                                  options:(SDWebImageDownloaderOptions)options
                                                                                  context:(nullable SDWebImageContext *)context {
                                                                                  //超时时间
    NSTimeInterval timeoutInterval = self.config.downloadTimeout;
    if (timeoutInterval == 0.0) {
        timeoutInterval = 15.0;
    }
    
    //省略部分逻辑判断及处理
    // 处理NSURLRequest
    NSURLRequest *request;
    if (requestModifier) {
        NSURLRequest *modifiedRequest = [requestModifier modifiedRequestWithRequest:[mutableRequest copy]];
        // If modified request is nil, early return
        if (!modifiedRequest) {
            return nil;
        } else {
            request = [modifiedRequest copy];
        }
    } else {
        request = [mutableRequest copy];
    }
    // Response Modifier
    id<SDWebImageDownloaderResponseModifier> responseModifier;
    if ([context valueForKey:SDWebImageContextDownloadResponseModifier]) {
        responseModifier = [context valueForKey:SDWebImageContextDownloadResponseModifier];
    } else {
        responseModifier = self.responseModifier;
    }
    if (responseModifier) {
        mutableContext[SDWebImageContextDownloadResponseModifier] = responseModifier;
    }
    // Decryptor
    id<SDWebImageDownloaderDecryptor> decryptor;
    if ([context valueForKey:SDWebImageContextDownloadDecryptor]) {
        decryptor = [context valueForKey:SDWebImageContextDownloadDecryptor];
    } else {
        decryptor = self.decryptor;
    }
    if (decryptor) {
        mutableContext[SDWebImageContextDownloadDecryptor] = decryptor;
    }
    
    context = [mutableContext copy];
    
    // Operation Class
    Class operationClass = self.config.operationClass;
    if (operationClass && [operationClass isSubclassOfClass:[NSOperation class]] && [operationClass conformsToProtocol:@protocol(SDWebImageDownloaderOperation)]) {
        // Custom operation class
    } else {
        operationClass = [SDWebImageDownloaderOperation class];
    }
    // 初始化下载的operation
    NSOperation<SDWebImageDownloaderOperation> *operation = [[operationClass alloc] initWithRequest:request inSession:self.session options:options context:context];
    
    if ([operation respondsToSelector:@selector(setCredential:)]) {
        if (self.config.urlCredential) {
            operation.credential = self.config.urlCredential;
        } else if (self.config.username && self.config.password) {
            operation.credential = [NSURLCredential credentialWithUser:self.config.username password:self.config.password persistence:NSURLCredentialPersistenceForSession];
        }
    }
        
    if ([operation respondsToSelector:@selector(setMinimumProgressInterval:)]) {
        operation.minimumProgressInterval = MIN(MAX(self.config.minimumProgressInterval, 0), 1);
    }
    
    if (options & SDWebImageDownloaderHighPriority) {
        operation.queuePriority = NSOperationQueuePriorityHigh;
    } else if (options & SDWebImageDownloaderLowPriority) {
        operation.queuePriority = NSOperationQueuePriorityLow;
    }
    
    if (self.config.executionOrder == SDWebImageDownloaderLIFOExecutionOrder) {
        // Emulate LIFO execution order by systematically, each previous adding operation can dependency the new operation
        // This can gurantee the new operation to be execulated firstly, even if when some operations finished, meanwhile you appending new operations
        // Just make last added operation dependents new operation can not solve this problem. See test case #test15DownloaderLIFOExecutionOrder
        for (NSOperation *pendingOperation in self.downloadQueue.operations) {
            [pendingOperation addDependency:operation];
        }
    }
    
    return operation;
}
```

然后在SDWebImageDownloaderOperation中有下载的具体实现，通过初始化中的request获取dataTask后执行resume。

以上就是主要流程，从UI层调用分类的接口，到manager类去查询缓存处理和未查询到缓存的执行下载处理，并最终返回回调到UI层中。

<br />

#### 1.3 零散的知识点

其实除了上述的主要流程，还有框架对不同格式的图片解码处理、大图优化处理、动图优化处理。后续持续研究。

这里选一些零散的知识点：

##### 1.3.1 将对应的类定义换成id<协议>

从上述流程中，发现了新版中很多属性中引用的类，从具体的某个类变成了id<协议>的形式，这是方便除了默认的实现类外还可以高度自定义，同时也可以在默认的类中加入更多的操作，从原本的调用中剥离出来。

比如SDWebImageManager中对缓存工具的引用

```
@property (strong, nonatomic, readonly, nonnull) id<SDImageCache> imageCache;
```

通过协议定义了默认类中带有的方法，并设置为必须实现。所以自定义的类在使用时，都会实现这些方法，并且也可以在对应的地方代码调用时可以直接关联上对应函数。

<br />

##### 1.3.2 弱引用的MapTable

在框架内使用了弱引用的map，可以不强引用map内的对象，并且可以在元素为nil时自动移除该元素，非常方便。

```
self.weakCache = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
```

同时在操作时也要保证线程安全，所有读写操作都进行了加锁操作。项目中使用的信号量进行加锁。

```
...
self.weakCacheLock = dispatch_semaphore_create(1);
...
SD_LOCK(self.weakCacheLock);
[self.weakCache setObject:obj forKey:key];
SD_UNLOCK(self.weakCacheLock);

#ifndef SD_LOCK
#define SD_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef SD_UNLOCK
#define SD_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif
```

<br />

##### 1.3.3 使用operation

项目中的多线程操作基本都是基于NSOperation，因为更方便管理和做判断等，大量的操作内部都会判断operation是否存在或者结束、暂停等。同时也方便外部对其执行优先级变更、取消等操作。

<br />