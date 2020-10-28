## iOS视频解码(软解)流程

### 1 简要说明

与上篇硬解一致，是同样类型的视频流。

解码一般分为硬解和软解。这篇主要说软解。当前项目使用的软解库是FFmpeg。

#### 1.1 FFmpeg简介

FFmpeg是视频处理最常用的软件框架。FFmpeg有很多强大的功能，包括视频采集功能、视频格式转换、视频抓图、给视频加水印等，还可以RTP方式将视频流传送给支持RTSP的流媒体服务器，支持直播应用。

使用FFmpeg作为内核的视频播放器：Mplayer，ffplay，射手播放器，暴风影音，KMPlayer，QQ影音...

使用FFMPEG作为内核的转码工具： 格式工厂...

只要做音视频开发，基本都脱离不开FFmpeg

#### 1.2 FFmpeg编译

在iOS开发中使用FFmpeg框架需要使用编译后的静态库。可以直接使用其他人编译好的库拉近项目中，也可以下载源码自行编译，也可以使用其他人写好的脚本直接编译。

此处只介绍通过写好的脚本编译，采用的FFmpeg的4.2版本。

##### 1.2.1 处理编译支持

首先先要下载编译支持的文件https://github.com/libav/gas-preprocessor

将gas-preprocesspr.pl文件拷贝到/usr/local/bin/中

然后执行终端命令

```
chmod 777 /usr/local/bin/gas-preprocessor.pl
```

然后安装yasm

执行命令

```
brew install yasm
```

##### 1.2.2 自动编译脚本

可以从该github地址中获得脚本：https://github.com/kewlbear/FFmpeg-iOS-build-script

下载下来后，直接在终端中执行

```
./build-ffmpeg.sh
```

即可，也可以针对arm64、armv7、x86_64来进行单独版本的编译

```
./build-ffmpeg.sh arm64
./build-ffmpeg.sh armv7 x86_64
```

编译后即可得到对应的静态库和头文件

![](图片1)

#### 1.3 项目中使用FFmpeg

将所有库文件和头文件添加到项目中后，还需要引入三个依赖库

```
libz.tbd
libbz2.tbd
libiconv.tbd
```

在Header Search Path中添加到include文件夹的相对路径

![](图片2)

然后在代码中通过以下方式引入

```
// FFmpeg Header File
#ifdef __cplusplus
extern "C" {
#endif
     
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libavutil/avutil.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/opt.h"
#include "libavutil/pixdesc.h"
#include "libavutil/imgutils.h"
     
#ifdef __cplusplus
};
#endif
```

### 2 软解流程图

![](图片3)

### 3 软解数据结构

FFmpeg软解中有几个对象和接口需要做说明，便于理解。

**AVCodec**：用于存储解码器信息的结构体，一般使用avcodec_find_decoder(AV_CODEC_ID_H264)创建，参数可以在库内查找到对应的支持解码的类型。

**AVCodecContext**：描述编解码器上下文的数据结构，包含了众多编解码器需要的参数信息。一般使用avcodec_alloc_context3(codec)创建，参数使用AVCodec创建。

**AVFrame**：存储经过解码后的原始数据。在解码中，AVFrame是解码器的输出；在编码中，AVFrame是编码器的输入。

**AVPacket**：解码前数据容器。包含原始数据和dts、pts等信息。一般使用av_new_packet创建。

**avcodec_send_packet**：进行解码的接口，放入解码器的队列中进行解码。

**avcodec_receive_frame**：从缓存队列中取出已解码数据的接口，取出的1个frame。

**sws_scale**：视频数据格式和分辨率的转换的接口，例如可以将YUV420的类型转成RGB的类型等。

### 4 软解实现流程代码和接口调用

根据2中的流程图来通过代码实现软解功能。

#### 4.1 初始化创建解码器、开启解码器

在负责解码的类初始化时即可初始化对应解码器

代码如下：

```
if (_codecType == VideoDecoderCodecH264) {
    codec = avcodec_find_decoder(AV_CODEC_ID_H264);
}
codecContext = avcodec_alloc_context3(codec);
avcodec_open2(codecContext, codec, nil);
```

#### 4.2 处理接收到的视频数据

因为项目中，设备传递包时，SPS-PPS-SEI-IDR是合起来的第一个包作为I帧，所以该项目里只要判断第一个00 00 00 01之后的字节 & 0x1F之后是不是7即可认为是I帧。同时 & 0x1F之后如果是1，认为是P帧。

软解时要确保I帧传入时是SPS-PPS-IDR在一个buffer内，不然解码操作会失败。

此处判断了SPS是否包含了IDR单元，可以不进行判断，因为TUTK项目编码时已做处理。

```
if (naluType == NALUTypeSPS || naluType == NALUTypeSEI || naluType == NALUTypePPS || naluType == NALUTypeIDR) {
    //判断SPS时是否带了IDR
    if (naluType == NALUTypeSPS) {
        @autoreleasepool {
            NSData *tempData = [NSData dataWithBytes:data length:size];
            NSRange range = [tempData rangeOfData:[NSData dataWithBytes:kBufferPrefix length:kNALUPrefixLength] options:NSDataSearchBackwards range:NSMakeRange(0, tempData.length)];
            if (range.length > 0) {
                tempData = [tempData subdataWithRange:NSMakeRange(range.location + range.length, 1)];
                uint8_t *tempBufferPrefix = (uint8_t *)[tempData bytes];
                NALUType tempNaluType = tempBufferPrefix[0] & 0x1F;
                //从后查询如果包含idr则认为是一个完整包
                if (tempNaluType == NALUTypeIDR) {
                    naluType = NALUTypeIDR;
                }
            }
 
        }
    }
    [self.frameData appendBytes:data length:size];
}
 
if (naluType == NALUTypeIDR || NALUTypeCodedSlice == naluType) {
     
    if (naluType == NALUTypeIDR) {
        int nalLen = (int)[self.frameData length];
        [self.ffmpegVideoDecoder decoderVideoWithData:(uint8_t *)[self.frameData bytes] size:nalLen timestamp:frameInfo.timestamp];
        self.frameData = [[NSMutableData alloc] init];
    } else {
        [self.ffmpegVideoDecoder decoderVideoWithData:data size:size timestamp:frameInfo.timestamp];
    }
}
```

#### 4.3 通过数据生成AVPacket

生成AVPacket时，因为项目的码流是不带B帧，所有pts额dts是同样的输出，直接赋值即可。

代码如下：

```
AVPacket *packet = av_packet_alloc();
av_new_packet(packet, size);
packet->size = size;
packet->pts = timestamp;
packet->dts = timestamp;
memcpy(packet->data, data, size);
```

#### 4.4 使用avcodec_send_packet和avcodec_receive_frame得到解码数据

处理解码数据时，判断出错的情况直接return。

需要注意一个AVPacket是有可能存在多个AVFrame。所以需要while一直去读取。

代码如下：

```
int ret = avcodec_send_packet(codecContext, packet);
if (ret < 0) {
    return;
}
 
int avcodecRet = 0;
while (avcodecRet >= 0) {
    avcodecRet = avcodec_receive_frame(codecContext, avFrame);
    if (avcodecRet == AVERROR(EAGAIN) || avcodecRet == AVERROR_EOF) {
        //            av_frame_free(&avFrame);
        return;
    }
    else if (avcodecRet < 0) {
        //            av_frame_free(&avFrame);
        return;
    }
}
```

#### 4.5 根据数据进行三种方式的渲染显示

因为该项目的数据流是采用的YUV420的y420P。

所以三种方式都需要转一下格式类型。

UIImage的方式需要将数据转成RGB。转完之后会将三段数据都放在第一段中。数据总长度多出一倍。

代码如下：

```
- (UIImage *)convertFrameToImage:(AVFrame *)pFrame {
     
    if (pFrame->data[0]) {
         
        int width = pFrame->width;
        int height = pFrame->height;
         
        struct SwsContext *scxt = sws_getContext(width, height, pFrame->format, width, height, AV_PIX_FMT_RGBA, SWS_FAST_BILINEAR, NULL, NULL, NULL);
        if (scxt == NULL) {
            return nil;
        }
        int det_bpp = av_get_bits_per_pixel(av_pix_fmt_desc_get(AV_PIX_FMT_RGBA));
        if (pFrame->key_frame) {
            av_freep(&pictureData[0]);
            av_image_alloc(pictureData, pictureLineSize, width, height, AV_PIX_FMT_RGBA, 1);
        }
         
        sws_scale(scxt, (const uint8_t **)pFrame->data, pFrame->linesize, 0, height, pictureData, pictureLineSize);
         
        CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pictureData[0], pictureLineSize[0] * height, kCFAllocatorNull);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGImageRef cgImage = CGImageCreate(width, height, 8, det_bpp, pictureLineSize[0], colorSpace, bitmapInfo, provider, NULL, NO, kCGRenderingIntentDefault);
        CGColorSpaceRelease(colorSpace);
        UIImage *image = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        CGDataProviderRelease(provider);
        CFRelease(data);
        sws_freeContext(scxt);
         
        return image;
    }
     
    return nil;
}
```

OpenGL和AVSampleBufferDisplayLayer方式，需要转成NV12，然后转成CMSampleBufferRef。转完后三段数据，会变成两段。

将FFmpeg解码后的YUV数据塞到CVPixelBuffer中，这里必须注意不能使用以下三种形式，否则将可能导致画面错乱或者绿屏或程序崩溃

```
memcpy(y_dest, y_src, w * h);
memcpy(y_dest, y_src, aFrame->linesize[0] * h);
memcpy(y_dest, y_src, CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) * h);
```

代码如下：

```
- (CVPixelBufferRef)createCVPixelBufferFromAVFrame:(AVFrame *)avFrame
                                               opt:(CVPixelBufferPoolRef)poolRef {
     
    if (avFrame->data[0] == NULL) {
        return NULL;
    }
    int width = avFrame->width;
    int height = avFrame->height;
     
    //先试用后FFmpeg的sws_scale 将门铃的格式Y420P 转成 PixelBuffer 支持的NV12
    struct SwsContext *scxt = sws_getContext(width, height, avFrame->format, width, height, AV_PIX_FMT_NV12, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    if (scxt == NULL) {
        return nil;
    }
    if (avFrame->key_frame) {
        av_freep(&pictureData[0]);
        av_image_alloc(pictureData, pictureLineSize, width, height, AV_PIX_FMT_NV12, 1);
    }
    sws_scale(scxt, (const uint8_t **)avFrame->data, avFrame->linesize, 0, height, pictureData, pictureLineSize);
    sws_freeContext(scxt);
    //从PixelBufferPool中创建PixelBuffer
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn result = kCVReturnError;
    if (poolRef) {
        result = CVPixelBufferPoolCreatePixelBuffer(NULL, poolRef, &pixelBuffer);
    } else {
        const int w = avFrame->width;
        const int h = avFrame->height;
        const int linesize = 32;//FFMpeg 解码数据对齐是32，这里期望CVPixelBuffer也能使用32对齐，但实际来看却是64！
         
        //AVCOL_RANGE_MPEG对应tv，AVCOL_RANGE_JPEG对应pc
        //Y′ values are conventionally shifted and scaled to the range [16, 235] (referred to as studio swing or "TV levels") rather than using the full range of [0, 255] (referred to as full swing or "PC levels").
        OSType pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
        [attributes setObject:@(linesize) forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
        [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
         
        result = CVPixelBufferCreate(kCFAllocatorDefault,
                                     w,
                                     h,
                                     pixelFormatType,
                                     (__bridge CFDictionaryRef)(attributes),
                                     &pixelBuffer);
    }
    //将数据 复制到 plane1 和 plane2 中
    if (kCVReturnSuccess == result) {
         
        CVPixelBufferLockBaseAddress(pixelBuffer,0);
         
        // Here y_src is Y-Plane of YUV(NV12) data.
        unsigned char *y_src  = pictureData[0];
        unsigned char *y_dest = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        size_t y_src_bytesPerRow  = pictureLineSize[0];
        size_t y_dest_bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        /*
         将FFmpeg解码后的YUV数据塞到CVPixelBuffer中，这里必须注意不能使用以下三种形式，否则将可能导致画面错乱或者绿屏或程序崩溃！
         memcpy(y_dest, y_src, w * h);
         memcpy(y_dest, y_src, aFrame->linesize[0] * h);
         memcpy(y_dest, y_src, CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) * h);
          
         原因是因为FFmpeg解码后的YUV数据的linesize大小是作了字节对齐的，所以视频的w和linesize[0]很可能不相等，同样的 CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) 也是作了字节对齐的，并且对齐大小跟FFmpeg的对齐大小可能也不一样，这就导致了最坏情况下这三个值都不等！我的一个测试视频的宽度是852，FFMpeg解码使用了32字节对齐后linesize【0】是 864，而 CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) 获取到的却是 896，通过计算得出使用的是 64 字节对齐的，所以上面三种 memcpy 的写法都不靠谱！
         【字节对齐】只是为了让CPU拷贝数据速度更快，由于对齐多出来的冗余字节不会用来显示，所以填 0 即可！目前来看FFmpeg使用32个字节做对齐，而CVPixelBuffer即使指定了32缺还是使用64个字节做对齐！
         以下代码的意思是：
         按行遍历 CVPixelBuffer 的每一行；
         先把该行全部填 0 ，然后把该行的FFmpeg解码数据（包括对齐字节）复制到 CVPixelBuffer 中；
         因为有上面分析的对齐不相等问题，所以只能一行一行的处理，不能直接使用 memcpy 简单处理！
         */
        for (int i = 0; i < height; i ++) {
            bzero(y_dest, y_dest_bytesPerRow);
            memcpy(y_dest, y_src, y_src_bytesPerRow);
            y_src  += y_src_bytesPerRow;
            y_dest += y_dest_bytesPerRow;
        }
         
        //此段本来是想自行转换Y420P到NV12 但使用了sws_scale就可以不用此操作了
        // Here uv_src is UV-Plane of YUV(NV12) data.
        // unsigned char *uv_src = avFrame->data[1];
        //此处做了处理 - 因为AVFrame是yuv420p，就需要把frame->data[1]和frame->data[2]的每一个字节交叉存储到pixelBUffer的plane1上，即把原来的uuuu和vvvv，保存成uvuvuvuv
        //        uint32_t size = pictureData[1] * avFrame->height;
        //        uint8_t *dstData = malloc(2 * size);
        //        for (int i = 0; i < 2 * size; i++) {
        //            if (i % 2 == 0){
        //                dstData[i] = avFrame->data[1][i/2];
        //            } else {
        //                dstData[i] = avFrame->data[2][i/2];
        //            }
        //        }
        unsigned char *uv_src = pictureData[1];
        unsigned char *uv_dest = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        size_t uv_src_bytesPerRow  = pictureLineSize[1];
        size_t uv_dest_bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
        /*
         对于 UV 的填充过程跟 Y 是一个道理，需要按行 memcpy 数据！
         */
        for (int i = 0; i < BYTE_ALIGN_2(height)/2; i ++) {
            bzero(uv_dest, uv_dest_bytesPerRow);
            memcpy(uv_dest, uv_src, uv_src_bytesPerRow);
            uv_src  += uv_src_bytesPerRow;
            uv_dest += uv_dest_bytesPerRow;
        }
         
        //此段是想将NV21转成NV12 但已经使用了sws_scale就可以不用此操作了
        //only swap VU for NV21
        //        if (avFrame->format == AV_PIX_FMT_NV21) {
        //            unsigned char *uv = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        //            /*
        //             将VU交换成UV；
        //             */
        //            for (int i = 0; i < BYTE_ALIGN_2(height)/2; i ++) {
        //                for (int j = 0; j < uv_dest_bytesPerRow - 1; j+=2) {
        //                    int v = *uv;
        //                    *uv = *(uv + 1);
        //                    *(uv + 1) = v;
        //                    uv += 2;
        //                }
        //            }
        //        }
        //        free(dstData);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    return pixelBuffer;
    //    return (CVPixelBufferRef)CFAutorelease(pixelBuffer);
}
 
- (CMSampleBufferRef)createCMSampleBufferFromCVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (pixelBuffer) {
        CFRetain(pixelBuffer);
        //不设置具体时间信息
        CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
        //获取视频信息
        CMVideoFormatDescriptionRef videoInfo = NULL;
        OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
        NSParameterAssert(result == 0 && videoInfo != NULL);
         
        CMSampleBufferRef sampleBuffer = NULL;
        result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
        NSParameterAssert(result == 0 && sampleBuffer != NULL);
        CFRelease(videoInfo);
         
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        CFRelease(pixelBuffer);
        return sampleBuffer;//(CMSampleBufferRef)CFAutorelease(sampleBuffer);
    }
    return NULL;
}
```

### 5 使用动态库解决FFmpeg静态库的冲突

静态库在项目会在开始编译时加载全部的文件，如果多个静态库出现同名的执行文件时，则在链接符号时就会有冲突，即使编译成功，运行后也只能链接到其中一个文件，多个静态库调用会指向同一个文件。

因为都是封装成的静态库，内部代码不能修改。

如果这个文件的版本不一致，代码实现不一致，调用时就会导致项目崩溃。

在调试时，发现原先的视频相关SDK包含了FFmpeg的3.4版本，而新项目开发引入的是FFmpeg4.2版本，并且原先的SDK编译是改过配置的，所以不管是链接到了哪个FFmpeg版本，都会出错和崩溃。

使用动态库就能解决该问题，各个动态库运行环境独立，即使包含同一名字的文件也不会引入错误。

因此制作了FFmpeg的动态库，将编译好的静态库放入动态库中，然后将视频和音频的解码操作封装成两个类，暴露相应的接口。