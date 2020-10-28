## iOS音视频流合成视频文件

### 1 简要说明

项目中，有录制视频的功能需求。需要将音视频的数据合成视频文件。

此项目中，采用的是解码后的音视频数据进行合并。采用系统AVFoundation框架中的AVAssetWriter进行合并生成。

尝试过两种文件格式mov和mp4的输出，都可以保存至系统相册中并且可以播放。

这两种视频容器，使用的音视频组合如下：

**mov** : h.264 + pcm

**mp4** : h.264 + aac

### 2 合成视频文件流程图

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E9%9F%B3%E8%A7%86%E9%A2%91%E6%B5%81%E5%90%88%E6%88%90%E8%A7%86%E9%A2%91%E6%96%87%E4%BB%B61.jpg?raw=true)

### 3 参数和接口说明

AVAssetWriter：实现媒体数据写入的功能类。

AVAssetWriterInput：实现输入源的接收和配置输出信息的功能。

AVAssetWriterInputPixelBufferAdaptor：使用PixelBuffer的输入源适配器。

canAddInput、addInput：AVAssetWriter判断和添加输入源接口。

startSessionAtSourceTime：开始接收数据流接口。

appendPixelBuffer：输入源适配器拼接数据接口。

appendSampleBuffer：输入源拼接数据接口。

markAsFinished：结束输入源接收的接口。

finishWritingWithCompletionHandler：结束的写入数据接口。

### 4 实现流程代码和接口调用

根据2中的流程图来通过代码实现硬解功能。

#### 4.1 初始化AVAssetWriter

fileType，AVFileTypeQuickTimeMovie对应的是mov，AVFileTypeMPEG4对应的是mp4。

代码如下：

```
// 重新构成AssetWriter
self.assetWriter = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:error];
```

#### 4.2 配置视频输出参数和输入参数并加入到AVAssetWriter中

其中此处使用AVAssetWriterInputPixelBufferAdaptor，适配PixelBuffer，可以方便后续解码出的CVPixelBuffer直接使用。

此处输出来类型为H264。合成出来的视频流在电脑客户端也是显示H264类型的视频，说明使用AVAssetWriter后系统是会将原始数据进行编码。

代码如下：

```
// 配置输出的视频参数
NSDictionary *videoOutputSettings = @{AVVideoCodecKey: AVVideoCodecTypeH264, AVVideoWidthKey: @(kDefaultVideoSize.width), AVVideoHeightKey: @(kDefaultVideoSize.height)};
if (self.videoInput) {
    self.videoInput = nil;
}
// 设置视频输入源
self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings];
self.videoInput.expectsMediaDataInRealTime = YES;
// 设置像素源参数
NSDictionary *sourcePixelBufferAttributes = @{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange), (NSString *)kCVPixelBufferWidthKey: videoOutputSettings[AVVideoWidthKey], (NSString *)kCVPixelBufferHeightKey: videoOutputSettings[AVVideoHeightKey]};
// 实例化视频适配器，用于将输入源的数据转换成视频
self.videoInputAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:sourcePixelBufferAttributes];
if (![self.assetWriter canAddInput:self.videoInput]) { // 如果写入器添加视频输入源失败
    *error = [NSError errorWithDomain:kStreamFilmerErrorDomain
                                  code:StreamFilmerErrorUnableAddVideoInput
                              userInfo:@{NSLocalizedDescriptionKey: @"无法添加视频输入源"}];
    [self.streamFilmerLock unlock];
    DDLogDebug(@"无法添加视频输入源");
    return NO;
}
[self.assetWriter addInput:self.videoInput];
```

#### 4.3 配置音频输出参数和输入参数并加入到AVAssetWriter中

其中可以设置输出参数，来定义输出的类型是aac还是pcm。

代码如下：

```
/// 因为我们目前是单声道的, 如果未来更改了. 这里也需要更改.
    AudioChannelLayout currentChannelLayout;
    bzero(&currentChannelLayout, sizeof(currentChannelLayout));
    currentChannelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
     
    AudioStreamBasicDescription asbd = audioFormat8k;
     
    // 设置音频输出参数
    NSDictionary *audioOutputSettings = @{AVFormatIDKey: @(kAudioFormatLinearPCM),
    AVSampleRateKey: @(asbd.mSampleRate),
    AVNumberOfChannelsKey: @(asbd.mChannelsPerFrame),
    AVChannelLayoutKey: [NSData dataWithBytes:&currentChannelLayout length: sizeof(currentChannelLayout)],
    AVLinearPCMBitDepthKey: @16,
    AVLinearPCMIsBigEndianKey: @NO,
    AVLinearPCMIsFloatKey: @NO,
    AVLinearPCMIsNonInterleaved: @NO
    };
     
//    NSDictionary *audioOutputSettings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
//    AVEncoderBitRatePerChannelKey: @(28000),
//    AVNumberOfChannelsKey: @(1),
//    AVSampleRateKey: @(22050)
//    };
    // 实例化音频输入源
    if (self.audioInput) {
        self.audioInput = nil;
    }
    self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    self.audioInput.expectsMediaDataInRealTime = YES;
     
    if (![self.assetWriter canAddInput:self.audioInput]) {
        *error = [NSError errorWithDomain:kStreamFilmerErrorDomain
                                     code:StreamFilmerErrorUnableAddAudioInput
                                 userInfo:@{NSLocalizedDescriptionKey: @"无法添加音频输入源"}];
        [self.streamFilmerLock unlock];
        DDLogDebug(@"无法添加音频输入源");
        return NO;
    }
    [self.assetWriter addInput:self.audioInput];
```

#### 4.4 写入视频流

中间要判断当前是否是静音，如果是静音要插入一段空数据音频。

代码如下：

```
if (AVAssetWriterStatusWriting == self.assetWriter.status && self.videoInputAdaptor.assetWriterInput.isReadyForMoreMediaData) {
    if (![self.videoInputAdaptor appendPixelBuffer:videoBuffer withPresentationTime:self.currentTime]) {
        DDLogError(@"无法拼接视频数据到视频中");
        return NO;
    }
     
    /// 如果声音停止了, 插入静音.
    if (self.audioStopped) {
        [self gatherAudioBuffer:NULL Length:0 Silent:YES];
    }
     
    self.currentTime = CMTimeAdd(self.currentTime, self.assetWriter.movieFragmentInterval);
    return YES;
}
```

#### 4.5 写入音频流

音频流需要使用CMBlockBuffer包装起来，然后生成SampleBuffer，才能通过输入源写入到文件中。

代码如下：

```
if (self.assetWriter.status == AVAssetWriterStatusWriting  && self.audioInput.isReadyForMoreMediaData) {
         
    CMBlockBufferRef blockBuffer = NULL;
    CMSampleBufferRef sampleBuffer = NULL;
    size_t audioBufferLength = isSilent ? IBLAudioDefaultBufferSize : (size_t)length;
    OSStatus status = noErr;
    if (!self.audioFormatDescription) {
        AudioStreamBasicDescription asbd = audioFormat8k;
        status = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, NULL, 0, NULL, NULL, &_audioFormatDescription);
        if (noErr != status) {
            DDLogError(@"实例化音频描述文件失败");
            return NO;
        }
    }
     
    status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, NULL, audioBufferLength, kCFAllocatorDefault, NULL, 0, audioBufferLength, 0, &blockBuffer);
     
    if (status != kCMBlockBufferNoErr) {
        DDLogError(@"实例化音频数据块失败");
        return NO;
    }
 
    if (isSilent) { // 这里要根据是否静音判断是将采集到的音频帧数据传入视频还是填入静音帧
        status = CMBlockBufferFillDataBytes(0, blockBuffer, 0, audioBufferLength);
        if (kCMBlockBufferNoErr != status) {
            DDLogError(@"无法填充静音数据块");
            return NO;
        }
    } else {
        status = CMBlockBufferReplaceDataBytes(audioBuffer, blockBuffer, 0, audioBufferLength);
        if (kCMBlockBufferNoErr != status) {
          DDLogError(@"无法将采集到的音频数据拷贝到音频数据块中");
          return NO;
        }
    }
     
    status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(kCFAllocatorDefault, blockBuffer, self.audioFormatDescription, audioBufferLength / 2, self.currentTime, NULL, &sampleBuffer);
     
    if (noErr != status) {
        DDLogError(@"无法生成视频数据块");
        return NO;
    }
     
    BOOL result = [self.audioInput appendSampleBuffer:sampleBuffer];
     
    if (!result) {
        DDLogError(@"无法将采集到的音频拼接到视频中");
    }
     
    CFRelease(blockBuffer);
    CFRelease(sampleBuffer);
     
    return result;
}
```

#### 4.6 完成音视频的写入

代码如下：

```
[self.videoInput markAsFinished];
[self.audioInput markAsFinished];
 
switch (type) {
    case StreamFilmerStopTypeNormol: {
            [self.assetWriter finishWritingWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    switch (self.assetWriter.status) {
                        case AVAssetWriterStatusCancelled:
                        case AVAssetWriterStatusFailed:{
                            DDLogError(@"无法录制视频: %@", self.assetWriter.error);
                            [[NSFileManager defaultManager] removeItemAtURL:self.assetWriter.outputURL error:nil];
                            !self.filmedCompletion ?: self.filmedCompletion(self.assetWriter.error);
                            self.filmedCompletion = nil;
                        }
                            break;
                         
                        case AVAssetWriterStatusCompleted: {
                            !self.filmedCompletion ?: self.filmedCompletion(nil);
                            self.filmedCompletion = nil;
                        }
                            break;
                             
                        default:
                            DDLogError(@"录制视频未知错误: %@", @(self.assetWriter.status));
                            break;
                    }
                });
                self.currentTime = kCMTimeZero;
                self.recording = NO;
                DDLogDebug(@"结束录制");
            }];
        }
        break;
    case StreamFilmerStopTypeCloseVideo:
    case StreamFilmerStopTypeReStart: {
            self.currentTime = kCMTimeZero;
            self.recording = NO;
            DDLogDebug(@"非正常结束录制");
        }
        break;
    default:
        break;
}
```

### 5 补充说明

目前项目中使用的只有这一种编成文件的方式。FFmpeg也可以合成mp4等视频文件，但目前还未研究完。

如果只是单纯的视频将数据硬编码，可以使用VideoTools内的VTCompressionSession类来进行编码，传入的参数也是使用PixelBuffer。

