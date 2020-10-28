## iOS视频渲染显示的三种方式

### 1 简要说明

视频解码后需要在页面图层中显示。该篇介绍解码后的数据渲染显示的三种方式。

分别是：UIImage、AVSampleBufferDisplayer、OpenGL

### 2 三种方式的实现方式

#### 2.1 UIImage

该种方式处理上最简单，也就是将一张一张的图，不断地赋值刷新。

视频解码后将数据变成UIImage的格式。然后通过UIImageView的image方式赋值即可。注意需要在主线程下进行。

代码如下：

```
dispatch_async(dispatch_get_main_queue(), ^{
    self.videoImageView.image = frameImage;
});
```

然后同样的，截图方法也可以直接取UIImage然后保存到相册即可。

代码如下：

```
capturedImage = self.videoImageView.image;
CGImageRef cgImage = capturedImage.CGImage;
if (!cgImage) {
    CIImage *ciImage = capturedImage.CIImage;
    if (!ciImage) {
        !self.screenShotHandler ?: self.screenShotHandler(nil, [NSError errorWithDomain:TCLStreamClientErrorDomain code:678 userInfo:@{@"info": @"未能获取当前图片"}]);
        self.screenShotHandler = nil;
        DDLogError(@"相册保存失败: 未能获取当前图片");
        return;
    }
    CIContext *context = [[CIContext alloc] init];
    cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
    capturedImage = [UIImage imageWithCGImage:cgImage];
    CFRelease(cgImage);
}
UIImageWriteToSavedPhotosAlbum(capturedImage, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
```

但通过TimeProfiler来观察，发现一直对UIImageView做image的赋值操作，并且频率很高，该项目中1秒20次左右，会占用较多CPU，所以不是特别推荐使用该方法。

#### 2.2 AVSampleBufferDisplayLayer

iOS8之后新出的用作渲染Layer，功能较少，不能像OpenGLES拥有多种视频操作，例如美颜、滤镜、部分拉伸等。如果项目仅用作显示可以使用该方式。

AVSampleBufferDisplayLayer需要加到你要显示的UIView上执行layer addSublayer操作。该Layer不仅可以渲染解码后的数据，也可以渲染解码前的数据，会自行解码然后渲染，非常方便。

传入渲染的数据格式使用的是CMSampleBufferRef，即之前硬解文章介绍过的数据结构，该种类型，即可以是解码前的容器，也可以是解码后的容器。所以不论是解码前还是解码后的sampleBuffer传入，都可以渲染出图像。

使用代码如下：

```
//设置部分渲染参数 包括是否需要解码等
CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(buffer, YES);
CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
//开始渲染显示
[self.displayLayer enqueueSampleBuffer:buffer];
```

虽然使用方便，但其和硬解有一样的问题，即从后台切换回前台时，渲染会失效，没有画面并黑屏。

处理方式是判断是否为指定的错误码，如果是则重新构建AVSampleBufferDisplayLayer。

代码如下：

```
[self.displayLayer enqueueSampleBuffer:buffer];
if (self.displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
    //从后台到前台。layer需要重置
    if (-11847 == self.displayLayer.error.code) {
        [self rebuildSampleBufferDisplayLayer];
    }
}
 
- (void)rebuildSampleBufferDisplayLayer {
    @synchronized(self) {
        [self teardownSampleBufferDisplayLayer];
        [self setupSampleBufferDisplayLayer];
    }
}
//取消当前Layer
- (void)teardownSampleBufferDisplayLayer {
    if (self.displayLayer) {
        [self.displayLayer stopRequestingMediaData];
        [self.displayLayer removeFromSuperlayer];
        self.displayLayer = nil;
    }
}
//重新生成Layer
- (void)setupSampleBufferDisplayLayer {
    if (!self.displayLayer) {
        self.displayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        self.displayLayer.frame = self.bounds;
        self.displayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        self.displayLayer.videoGravity = AVLayerVideoGravityResize;
        self.displayLayer.opaque = YES;
        [self.layer addSublayer:self.displayLayer];
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.displayLayer.frame = self.bounds;
        self.displayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [CATransaction commit];
    }
}
```

截图的话需要将解码后得到的CMSampleBufferRef存起来，执行截图时取出并转换成UIImage，然后再保存到相册中。

截取前保存CMSampleBufferRef的代码如下：

```
@synchronized(self) {
    if (currentBuffer) {
        CFRelease(currentBuffer);
        currentBuffer = nil;
    }
    currentBuffer = (CMSampleBufferRef)CFRetain(buffer);
}
```

当执行截图时，将buffer转成UIImage，代码如下：

```
- (UIImage *)currentImage {
    UIImage *uiImage = nil;
    @synchronized(self) {
        if (currentBuffer) {
            CVPixelBufferRef pix = CMSampleBufferGetImageBuffer(currentBuffer);
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pix];
            uiImage = [UIImage imageWithCIImage:ciImage];
            CFRelease(currentBuffer);
            currentBuffer = nil;
        }
    }
    return uiImage;
}
```

使用AVSampleBufferDisplayLayer方式，消耗的内存最小，CPU一般，同时当全屏时CPU消耗会稍微增大。

#### 2.3 OpenGL

当前项目中使用的是网上一个现成的OpenGL渲染的类，传入的参数是CVPixelBufferRef。

下面仅对渲染的代码做部分解释

##### 2.3.1 创建EAGLcontext上下文对象

创建OpenGL预览层

```
CAEAGLLayer *eaglLayer    = (CAEAGLLayer *)self.layer;
eaglLayer.opaque = YES;
eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking  : [NSNumber numberWithBool:NO],
                 ``kEAGLDrawablePropertyColorFormat    : kEAGLColorFormatRGBA8};
```

创建OpenGL上下文对象

```
EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
[EAGLContext setCurrentContext:context];
```

设置上下文渲染缓冲区

```
- (void)setupBuffersWithContext:(EAGLContext *)context width:(int *)width height:(int *)height colorBufferHandle:(GLuint *)colorBufferHandle frameBufferHandle:(GLuint *)frameBufferHandle {
    glDisable(GL_DEPTH_TEST);
     
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
     
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
     
    glGenFramebuffers(1, frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, *frameBufferHandle);
     
    glGenRenderbuffers(1, colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, *colorBufferHandle);
     
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH , width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, height);
     
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, *colorBufferHandle);
}
```

加载着色器

该类目前只添加了NV12格式的和RGB格式

```
- (void)loadShaderWithBufferType:(XDXPixelBufferType)type {
    GLuint vertShader, fragShader;
    NSURL  *vertShaderURL, *fragShaderURL;
     
    NSString *shaderName;
    GLuint   program;
    program = glCreateProgram();
     
    if (type == XDXPixelBufferTypeNV12) {
        shaderName = @"XDXPreviewNV12Shader";
        _nv12Program = program;
    } else if (type == XDXPixelBufferTypeRGB) {
        shaderName = @"XDXPreviewRGBShader";
        _rgbProgram = program;
    }
     
    vertShaderURL = [[NSBundle mainBundle] URLForResource:shaderName withExtension:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER URL:vertShaderURL]) {
        DDLogDebug(@"Failed to compile vertex shader");
        return;
    }
     
    fragShaderURL = [[NSBundle mainBundle] URLForResource:shaderName withExtension:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER URL:fragShaderURL]) {
        DDLogDebug(@"Failed to compile fragment shader");
        return;
    }
     
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
     
    glBindAttribLocation(program, ATTRIB_VERTEX  , "position");
    glBindAttribLocation(program, ATTRIB_TEXCOORD, "inputTextureCoordinate");
     
    if (![self linkProgram:program]) {
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
        return;
    }
     
    if (type == XDXPixelBufferTypeNV12) {
        uniforms[UNIFORM_Y] = glGetUniformLocation(program , "luminanceTexture");
        uniforms[UNIFORM_UV] = glGetUniformLocation(program, "chrominanceTexture");
        uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = glGetUniformLocation(program, "colorConversionMatrix");
    } else if (type == XDXPixelBufferTypeRGB) {
        _displayInputTextureUniform = glGetUniformLocation(program, "inputImageTexture");
    }
     
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
}
```

创建视频纹理缓存区

```
if (!*videoTextureCache) {
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, videoTextureCache);
    if (err != noErr)
        DDLogDebug(@"Error at CVOpenGLESTextureCacheCreate %d",err);
}
```

##### 2.3.2 将PixelBuffer渲染

渲染前先清空缓存数据

```
- (void)cleanUpTextures {
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
     
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
     
    if (_renderTexture) {
        CFRelease(_renderTexture);
        _renderTexture = NULL;
    }
     
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}
```

根据PixelBuffer确认视频格式的数据类型

```
XDXPixelBufferType bufferType;
if (CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange || CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
    bufferType = XDXPixelBufferTypeNV12;
} else if (CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA) {
    bufferType = XDXPixelBufferTypeRGB;
} else {
    DDLogDebug(@"Not support current format.");
    return;
}
```

通过当前的Buffer创建CVOpenGLESTexture对象

```
CVOpenGLESTextureRef lumaTexture,chromaTexture,renderTexture;
if (bufferType == XDXPixelBufferTypeNV12) {
    // Y
    glActiveTexture(GL_TEXTURE0);
     
    error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          videoTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_LUMINANCE,
                                                          frameWidth,
                                                          frameHeight,
                                                          GL_LUMINANCE,
                                                          GL_UNSIGNED_BYTE,
                                                          0,
                                                          &lumaTexture);
    if (error) {
        DDLogDebug(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
    }else {
        _lumaTexture = lumaTexture;
    }
     
    glBindTexture(CVOpenGLESTextureGetTarget(lumaTexture), CVOpenGLESTextureGetName(lumaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     
    // UV
    glActiveTexture(GL_TEXTURE1);
    error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          videoTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_LUMINANCE_ALPHA,
                                                          frameWidth / 2,
                                                          frameHeight / 2,
                                                          GL_LUMINANCE_ALPHA,
                                                          GL_UNSIGNED_BYTE,
                                                          1,
                                                          &chromaTexture);
    if (error) {
        DDLogDebug(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
    }else {
        _chromaTexture = chromaTexture;
    }
     
    glBindTexture(CVOpenGLESTextureGetTarget(chromaTexture), CVOpenGLESTextureGetName(chromaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     
} else if (bufferType == XDXPixelBufferTypeRGB) {
    // RGB
    glActiveTexture(GL_TEXTURE0);
    error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                          videoTextureCache,
                                                          pixelBuffer,
                                                          NULL,
                                                          GL_TEXTURE_2D,
                                                          GL_RGBA,
                                                          frameWidth,
                                                          frameHeight,
                                                          GL_BGRA,
                                                          GL_UNSIGNED_BYTE,
                                                          0,
                                                          &renderTexture);
    if (error) {
        DDLogDebug(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", error);
    }else {
        _renderTexture = renderTexture;
    }
     
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}
```

选择OpenGL程序

```
glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
     
glViewport(0, 0, backingWidth, backingHeight);
 
glClearColor(0.1f, 0.0f, 0.0f, 1.0f);
glClear(GL_COLOR_BUFFER_BIT);
 
if (bufferType == XDXPixelBufferTypeNV12) {
    if (self.lastBufferType != bufferType) {
        glUseProgram(nv12Program);
        glUniform1i(uniforms[UNIFORM_Y], 0);
        glUniform1i(uniforms[UNIFORM_UV], 1);
        glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, preferredConversion);
    }
} else if (bufferType == XDXPixelBufferTypeRGB) {
    if (self.lastBufferType != bufferType) {
        glUseProgram(rgbProgram);
        glUniform1i(displayInputTextureUniform, 0);
    }
}
```

渲染画面

```
glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData);
glEnableVertexAttribArray(ATTRIB_VERTEX);
 
glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData);
glEnableVertexAttribArray(ATTRIB_TEXCOORD);
 
glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
 
glBindRenderbuffer(GL_RENDERBUFFER, colorBufferHandle);
 
if ([EAGLContext currentContext] == context) {
    [context presentRenderbuffer:GL_RENDERBUFFER];
}
```

##### 2.3.3 截图实现

截图功能的实现也和AVSampleBufferDisplayLayer一样，保存buffer。当执行截图操作时，将buffer转换成UIImage。

收到buffer时缓存

```
@synchronized(self) {
    if (currentBuffer) {
        CFRelease(currentBuffer);
        currentBuffer = nil;
    }
    currentBuffer = (CVPixelBufferRef)CFRetain(pixelBuffer);
}
```

截图操作时转换成UIImage

```
- (UIImage *)currentImage {
    UIImage *uiImage = nil;
    @synchronized(self) {
        if (currentBuffer) {
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:currentBuffer];
            uiImage = [UIImage imageWithCIImage:ciImage];
            CFRelease(currentBuffer);
            currentBuffer = nil;
        }
    }
    return uiImage;
}
```

使用OpenGL方式，是CPU占用最少的，内存占用一般，但是调试的时候发现显示占用GPU。

