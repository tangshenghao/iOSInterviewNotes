## iOS视频解码(硬解)流程

### 1 简要说明

此篇只针对我接手的一个项目来进行说明，在这个项目中视频流是以H.264裸流通过SDK进行传输。也就是通过SDK，我们只能连接SDK方的云服务和设备、获取设备推过来的裸流以及指令的控制等。SDK中不包含播放器等功能，所以需要自行实现解码和渲染显示。所以需要进行解码，也就有了此篇说明。

解码一般分为硬解和软解。这篇主要说硬解。iOS的硬解使用的是VideoToolbox的框架。在iOS8.0之后苹果才引入。iOS8.0之前不能使用该框架。Mac OS一直都有。

该项目中的视频数据是以H.264为标准，Start Code为00 00 00 01。其中I帧的数据包含SPS、PPS、SEI和IDR。I帧间有59个P帧。DTS和PTS都是一样的输出。采样的数据格式是以420P为标准。

### 2 硬解流程图

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E8%A7%86%E9%A2%91%E8%A7%A3%E7%A0%81(%E7%A1%AC%E8%A7%A3)%E6%B5%81%E7%A8%8B1.jpg?raw=true)

### 3 硬解数据结构

硬解中有几个对象需要做说明，便于理解。

**CMSampleBuffer**：用来作解码前和解码后的容器。

如下图所示：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E8%A7%86%E9%A2%91%E8%A7%A3%E7%A0%81(%E7%A1%AC%E8%A7%A3)%E6%B5%81%E7%A8%8B2.png?raw=true)

CMSampleBuffer即可以作为未解码前的数据的容器，可以用压缩的数据CMBlockBuffer来生成。也可以作为解码后的数据的容器，可以解出CVPixelBuffer或者根据CVPixelBuffe生成。

**CVPixelBuffer**：解码后的图像数据结构

**CMBlockBuffer**：编码后图像的数据结构

**CMVideoFormatDescription**：图像的存储方式，解码器等格式描述。

**CMTime**：时间戳结构。时间以 64-bit/32-bit形式出现。 分子是64-bit的时间值，分母是32-bit的时标(time scale)

以下的是硬解码的主要接口说明：

**VTDecompressionSessionCreate**：生成解码器需要的session，配置信息。

**VTDecompressionSessionInvalidate**：释放解码器的session。

**VTDecompressionSessionDecodeFrame**：对CMSampleBufferRef进行解码的接口。

**VTDecompressionOutputCallbackRecord**：解码后的回调设置。

### 4 硬解实现流程代码和接口调用

根据2中的流程图来通过代码实现硬解功能。

#### 4.1 对接收到的buffer数据先分析判断是不是SPS-PPS-SEI-IDR的那一包

因为在该项目中，设备传递视频数据包时，SPS-PPS-SEI-IDR是合起来的第一个包作为I帧，所以该项目里只要判断第一个00 00 00 01之后的字节 & 0x1F之后是不是7即可认为是I帧。同时 & 0x1F之后如果是1，认为是P帧。

但如果是别的项目，可能要对包做处理，因为有可能，SPS-PPS作为一个包过来，IDR作为另一个包过来，所以是这种情况，就要将两个包合起来处理，或者做好区分即可。

代码如下：

```
/// 获取这包数据的第一个 NALU 类型.
int bufferPrefix = imageBuffer[4];
NALUType naluType = bufferPrefix & 0x1F;
//该项目I帧会以 {SPS-PPS-SEI-IDR} 为一包。剩余以P帧传递。所以此处只判断开头是否为SPS和0x01Slice包
if (naluType == NALUTypeSPS || naluType == NALUTypeCodedSlice) {
    //处理这两种包
    CMSampleBufferRef sampleBuffer = NULL;
    sampleBuffer = [self sampleH264BufferWithBuffer:imageBuffer Length:readSize NALUType:naluType];
}
```

#### 4.2 获取SPS、PPS等数据

从4.1中，可以得到包含SPS、PPS、SEI和IDR的包。

此时将每个NALU中的Startcode之后的数据保存起来。提取SPS、PPS。

```
/// 如果第一个 NALU 是 SPS 类型, 我们需要找出后面跟着的 PPS 和 IDR.
if (naluType == NALUTypeSPS) { // 取到了I帧开头的NALU类型
     
    DataLengthCalculationBlock calculateDataLength = ^NSUInteger(size_t begin) {
        for (NSUInteger i = begin; i < length; i++) {
            if (1 == memcmp(buffer + i, kBufferPrefix, kNALUPrefixLength)) {
                NSUInteger offset = MIN(i + kNALUPrefixLength, length - 1);
                return offset - begin;
            }
        }
        return length - begin;
    };
     
    for (NSUInteger i = 0; i < length; i++) {
        if (memcmp(buffer + i, kBufferPrefix, kNALUPrefixLength) == 0) {
            size_t offset = MIN(i+kNALUPrefixLength, length - 1);
            NALUType nalu = buffer[offset] & 0x1F;
            switch (nalu) {
                case NALUTypeCodedSlice:/// 如果是 P 帧, 那么整个包都是 P 帧数据.
                    _idrData = [NSData dataWithBytesNoCopy:buffer length:length freeWhenDone:NO];
                    break;
                case NALUTypeSPS: {
                    NSUInteger tempLength = calculateDataLength(offset);
                    _spsData = [NSData dataWithBytes:&buffer[offset] length:tempLength];
              }
                    break;
                case NALUTypePPS: {
                    NSUInteger tempLength = calculateDataLength(offset);
                    _ppsData = [NSData dataWithBytes:&buffer[offset] length:tempLength];
              }
                    break;
                case NALUTypeSEI: {
                    NSUInteger tempLength = calculateDataLength(offset);
                    _seiData = [NSData dataWithBytes:&buffer[offset] length:tempLength];
              }
                    break;
                case NALUTypeIDR:
                    _idrData = [NSData dataWithBytesNoCopy:&buffer[offset - kNALUPrefixLength] length:length - offset + kNALUPrefixLength freeWhenDone:NO];
                    break;
               
                default:
                    NSAssert(NO, @"未识别的Nalu类型: %@", [self naluNameWithType:nalu]);
                    break;
              }
        }
    }
     
    /// 如果我们没有得到格式数据, 输出视频数据方便 Debug.
    if (!_spsData || !_ppsData) {
        NSMutableString *string  = [NSMutableString string];
        for (NSUInteger i = 0; i < 30; i++) {
            [string appendFormat:@"%02X", buffer[i]];
        }
        DDLogVerbose(@"I帧数据不全 spsData is %@, ppsData is %@, header is %@", _spsData, _ppsData, string);
        return NULL;
    }
```

#### 4.3 判断SPS和PPS是不是和之前的不一致，或是首次收到SPS和PPS

获取旧的SPS和PPS可以使用

通过`CMVideoFormatDescriptionGetH264ParameterSetAtIndex`来获取

代码如下：

```
/// 检查格式是否有变化(例如码流等参数变了), 如果有变化需要重新创建 `VTDecompressionSessionRef`.
         
NSUInteger naluChanges = 0; // 检查SPS和PPS是否变化
 
NSUInteger const parameterCount = 2;
 
const uint8_t * const parameterSetPointers[parameterCount] = {[_spsData bytes], [_ppsData bytes]};
const size_t parameterSetSizes[parameterCount] = {_spsData.length, _ppsData.length};
 
for (int i = 0; _formatDescription && i < parameterCount; i++) {
    size_t oldLength = 0;
    const uint8_t *oldData = NULL;
    status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(_formatDescription, i, &oldData, &oldLength, NULL, NULL);
     
    if (status != noErr) {
        _formatDescription = NULL;
        DDLogError(@"无法获取视频格式描述: %d", (int)status);
        return NULL;
    }
     
    if (memcmp(parameterSetPointers[i], oldData, oldLength) !=0 || oldLength != parameterSetSizes[i]) {
        naluChanges ++;
    }
}
 
BOOL isVideoFormatChanged = naluChanges == parameterCount;
```

#### 4.4 如果首次接收或者SPS和PPS和之前的不一致了，需要生成解码器和重置session

生成解码器，使用`CMVideoFormatDescriptionCreateFromH264ParameterSets`来生成。

代码如下：

```
if (!_decompressionSession || isVideoFormatChanged) {
    // 没有解压Session或视频码流格式已经变化
    DDLogDebug(@"生成新的格式描述");
    // 生成用于H264的格式描述
    status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, parameterCount, parameterSetPointers, parameterSetSizes, kNALUPrefixLength, &_formatDescription);
    if (status != noErr) {
        DDLogError(@"生成视频码流格式描述失败: %d", (int)status);
        _formatDescription = NULL;
        return NULL;
    }
    [self freeDecompressionSession]; // 释放解压Session
    if (![self initializeDecompressionSession]) { // 尝试根据视频解码格式生成新的解码Session
        return NULL;
    };
}
```

#### 4.5 通过数据生成BlockBuffer

I帧包的数据里取IDR的数据，如果是P帧，直接使用。

通过数据生成BlockBuffer，使用`CMBlockBufferCreateWithMemoryBlock`来生成。

代码如下：

```
void *blockData = (void *)[_idrData bytes];
size_t blockDataLength = (size_t)_idrData.length;
CMBlockBufferRef blockBuffer = NULL;
// 将视频数据封装进解码所需的数据块中
status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, blockData, blockDataLength, kCFAllocatorNull, NULL, 0, blockDataLength, 0, &blockBuffer);
if (kCMBlockBufferNoErr != status) {
    DDLogError(@"无法创建解码数据块: %d", (int)status);
    blockBuffer = NULL;
    return NULL;
}
```

#### 4.6 将Annex B的startcode转换成AVCC格式头

因为iOS硬解码，只支持AVCC格式头，所以需要将00 00 00 01开头的startcode，转换成后面数据长度的startcode。填满4个字节。

使用`CMBlockBufferReplaceDataBytes`来执行替换。

代码如下：

```
/// 转换 Header 为 Length.
size_t removeHeaderSize = blockDataLength - kNALUPrefixLength;
const uint8_t lengthBytes[kNALUPrefixLength] = {(uint8_t)(removeHeaderSize >> 24),
                                                (uint8_t)(removeHeaderSize >> 16),
                                                (uint8_t)(removeHeaderSize >> 8),
                                                (uint8_t) removeHeaderSize};
// 清空头部内容
status = CMBlockBufferReplaceDataBytes(lengthBytes, blockBuffer, 0, kNALUPrefixLength);
if (kCMBlockBufferNoErr != status) {
    DDLogError(@"清空数据块头部失败，释放数据块: %d", (int)status);
    CFRelease(blockBuffer);
    return NULL;
}
```

#### 4.7 根据CMBlockBufferRef和CMVideoFormatDescriptionRef生成CMSampleBuffer

使用`CMSampleBufferCreateReady`生成CMSampleBuffer。

代码如下：

```
const size_t sampleSizeArray[] = {length};
CMSampleBufferRef sampleBuffer = NULL;
 
// 生成一个CMSampleBuffer
status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _formatDescription, 1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
if (noErr != status) {
    DDLogError(@"CMSampleBuffer生成失败: %d", (int)status);
    CFRelease(blockBuffer);
    return NULL;
}
```

过程如下图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E8%A7%86%E9%A2%91%E8%A7%A3%E7%A0%81(%E7%A1%AC%E8%A7%A3)%E6%B5%81%E7%A8%8B3.png?raw=true)

其中CMTime在这个项目中可以不加入，也能生成正常使用的CMSampleBuffer。

#### 4.8 使用VTDecompressionSessionDecodeFrame进行解码

代码如下：

```
// 将SampleBuffer扔到解压Session中执行解压
OSStatus status = VTDecompressionSessionDecodeFrame(_decompressionSession, sampleBuffer, 0, NULL, NULL);
if (noErr != status) {
    DDLogError(@"帧解码失败: %d", (int)status);
    CFRelease(sampleBuffer);
    if (status == kVTInvalidSessionErr) {
        //重后台回到前台，需要重新重置VTDecompressionSessionRef，不然会一直黑屏
        [self freeDecompressionSession];
        [self initializeDecompressionSession];
    }
    return NO;
}
```

其中需要注意的是，解码过程中途从后台切换到前台时，`decompressionSession`会失效，需要在解码得到的OSStatus中进行判断，如果是`kVTInvalidSessionErr`，则需要重新重置`VTDecompressionSessionRef`。不然会一直黑屏。

#### 4.9 通过回调得到解码后的数据，根据数据进行三种方式的渲染显示

回调函数会用到的返回

`OSStatus`：解码的成功与否状态

`CVImageBufferRef`：解码之后的buffer数据

`CMTime`：两个CMTime，presentationTimeStamp是PTS。presentationDuration是时间段。

其中UIImage的方式可以直接通过`CVImageBufferRef`转。

```
CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
UIImage *image = [UIImage imageWithCIImage:ciImage];
```

OpenGL和AVSampleBufferDisplayLayer方式，需要将CVImageBufferRef转成CMSampleBufferRef。

转换实现如下：

```
ToolsDecodeVideoInfo *sourceRef = (ToolsDecodeVideoInfo *)sourceFrameRefCon;
         
        CMSampleTimingInfo sampleTime = {
            .presentationTimeStamp  = presentationTimeStamp,
            .decodeTimeStamp        = presentationTimeStamp
        };
         
        CMSampleBufferRef samplebuffer = [videoDecoder createSampleBufferFromPixelbuffer:imageBuffer videoRotate:(sourceRef ? sourceRef->rotate : 1) timingInfo:sampleTime];
}
 
- (CMSampleBufferRef)createSampleBufferFromPixelbuffer:(CVImageBufferRef)pixelBuffer videoRotate:(int)videoRotate timingInfo:(CMSampleTimingInfo)timingInfo {
    if (!pixelBuffer) {
        return NULL;
    }
     
    CVPixelBufferRef final_pixelbuffer = pixelBuffer;
    CMSampleBufferRef samplebuffer = NULL;
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus status = CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, final_pixelbuffer, &videoInfo);
    status = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, final_pixelbuffer, true, NULL, NULL, videoInfo, &timingInfo, &samplebuffer);
     
    if (videoInfo != NULL) {
        CFRelease(videoInfo);
    }
     
    if (samplebuffer == NULL || status != noErr) {
        return NULL;
    }
     
    return samplebuffer;
}
```

解码后处理如下：

```
static void decompressionOutputCallback(void * CM_NULLABLE decompressionOutputRefCon,
                                        void * CM_NULLABLE sourceFrameRefCon,
                                        OSStatus status,
                                        VTDecodeInfoFlags infoFlags,
                                        CM_NULLABLE CVImageBufferRef imageBuffer,
                                        CMTime presentationTimeStamp,
                                        CMTime presentationDuration) {
     
    if (noErr != status || imageBuffer == NULL) {
        DDLogError(@"SampleBuffer解码失败: %d", (int)status);
        return;
    }
     
    [[StreamFilmer sharedFilmer] gatherVideoBuffer:imageBuffer];
     
    VideoToolsDecoder *videoDecoder = (__bridge VideoToolsDecoder *)(decompressionOutputRefCon);
     
    switch (videoDecoder.renderType) {
        case VideoToolsRenderTypeUIImage: {
            //Image方式解码回调-执行转UIImage处理
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
            UIImage *image = [UIImage imageWithCIImage:ciImage];
            if ([videoDecoder.delegate respondsToSelector:@selector(videoToolsDecoder:RenderedFrameImage:)]) {
                [videoDecoder.delegate videoToolsDecoder:videoDecoder RenderedFrameImage:image];
            }
            break;
        }
        case VideoToolsRenderTypeAVSampleBuffer:
        case VideoToolsRenderTypeOpenGL: {
            //AVSampleBuffer和OpenGL都使用同样的数据格式SampleBuffer
            //将解码数据拼装生成SampleBuffer
            ToolsDecodeVideoInfo *sourceRef = (ToolsDecodeVideoInfo *)sourceFrameRefCon;
            CMSampleTimingInfo sampleTime = {
                .presentationTimeStamp  = presentationTimeStamp,
                .decodeTimeStamp        = presentationTimeStamp
            };
            CMSampleBufferRef samplebuffer = [videoDecoder createSampleBufferFromPixelbuffer:imageBuffer videoRotate:(sourceRef ? sourceRef->rotate : 1) timingInfo:sampleTime];
            if (samplebuffer) {
                if ([videoDecoder.delegate  respondsToSelector:@selector(videoToolsDecoder:renderedSampleBuffer:)]) {
                    [videoDecoder.delegate videoToolsDecoder:videoDecoder renderedSampleBuffer:samplebuffer];
                }
                CFRelease(samplebuffer);
            }
            if (sourceRef) {
                free(sourceRef);
            }
            break;
        }
        default:
            break;
    }
}
```

同时实际上如果选择了AVSampleBufferDisplayLayer的方式，也可以在没有解码之前，就将CMSampleBufferRef数据传入也可以渲染出图像。系统会自动解码并显示。