## iOS音频解码(c和FFMpeg)

### 1 简要说明

在项目中，音频使用的是G711U的编码格式。下面说一下G.711的编码原理。

#### 1.1 G.711简介

G.711是国际电信联盟定制出来的一套语音压缩标准，它代表了对PCM抽样标准，是主流的波形声音编解码标准，常用于电话语音。

- 主要用脉冲编码调制对音频采样，采样率为8k每秒。它利用一个 64Kbps 未压缩通道传输语音讯号。
- 压缩率为1：2， 即把16位成8位。

G.711标准下主要有两种压缩算法。

**u-law**：也称为G711U，主要运用于北美和日本。

**a-law**：也称为G711A，主要用于欧洲和世界其他地区，特别设计用来方便计算机处理的。

G.711将14bit或者13bit采样的PCM数据编码成8bit的数据流，播放的时候在将此8bit的数据还原成14bit或者13bit进行播放。G711是波形编解码算法，就是一个sample对应一个编码，所以压缩比固定为：

8/14 = 57%（u-law）

8/13 = 62%（a-law）

#### 1.2 G.711原理

G.711是将语音模拟信号进行一种非线性量化。下面主要列出一些性能参数：

G.711 (PCM方式)

**采样率**：8kHz

**信息量**：64kbps / channel

**理论延迟**：0.125msec

**品质**：MOS值4.10

算法原理：

##### 1.2.1 a-law

a-law的公式如下，A = 87.6

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E9%9F%B3%E9%A2%91%E8%A7%A3%E7%A0%81(c%E5%92%8CFFMpeg)1.png?raw=true)

G.711A

输入的是13位（S16的高13位），这种格式是经过特别设计的，便于数字设备进行快速运算。

1. 取符号位并取反得到s。
2. 获取强度位eee，获取方法如下图所示
3. 获取高位样本位wxyz
4. 组合为seeewxyz，将seeewxyz逢偶数为取补数。

a-law如下表计算。

- 第一列是采样点，共13bit，最高位为符号位。
- 对于前两行，折线斜率均为1/2，跟负半段的相应区域位于同一段折线上。
- 对于3到8行，斜率分别是1/4到1/128，共6段折线。
- 总共13段折线，这就是所谓的A-law十三段折线法。

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E9%9F%B3%E9%A2%91%E8%A7%A3%E7%A0%81(c%E5%92%8CFFMpeg)2.png?raw=true)

**示例：**

输入pcm数据为1234，二进制对应为（0000 0100 1101 0010）
二进制变换下排列组合方式（0 00001 0011 010010）

1. 获取符号位最高位为0，取反，s=1
2. 获取强度位00001，查表，编码制应该是eee=01
3. 获取高位样本wxyz=00
4. 组合为10110011，逢偶数为取反为11100110，得到E6

c算法实现如下：

```
#define SIGN_BIT    (0x80)      /* Sign bit for a A-law byte. */
#define QUANT_MASK  (0xf)       /* Quantization field mask. */
#define NSEGS       (8)     /* Number of A-law segments. */
#define SEG_SHIFT   (4)     /* Left shift for segment number. */
#define SEG_MASK    (0x70)      /* Segment field mask. */
static int seg_aend[8] = {0x1F, 0x3F, 0x7F, 0xFF,
                0x1FF, 0x3FF, 0x7FF, 0xFFF};
static int seg_uend[8] = {0x3F, 0x7F, 0xFF, 0x1FF,
                0x3FF, 0x7FF, 0xFFF, 0x1FFF};
  
static int search(
    int val,    /* changed from "short" *drago* */
    int *   table,
    int size)   /* changed from "short" *drago* */
{
    int i;      /* changed from "short" *drago* */
  
    for (i = 0; i < size; i++) {
        if (val <= *table++)
            return (i);
    }
    return (size);
}
  
int linear2alaw(int pcm_val)        /* 2's complement (16-bit range) */
                                        /* changed from "short" *drago* */
{
    int     mask;   /* changed from "short" *drago* */
    int     seg;    /* changed from "short" *drago* */
    int     aval;
  
    pcm_val = pcm_val >> 3;//这里右移3位，因为采样值是16bit，而A-law是13bit，存储在高13位上，低3位被舍弃
  
  
    if (pcm_val >= 0) {
        mask = 0xD5;        /* sign (7th) bit = 1 二进制的11010101*/
    } else {
        mask = 0x55;        /* sign bit = 0  二进制的01010101*/
        pcm_val = -pcm_val - 1; //负数转换为正数计算
    }
  
    /* Convert the scaled magnitude to segment number. */
    seg = search(pcm_val, seg_aend, 8); //查找采样值对应哪一段折线
  
    /* Combine the sign, segment, and quantization bits. */
  
    if (seg >= 8)       /* out of range, return maximum value. */
        return (0x7F ^ mask);
    else {
//以下按照表格第一二列进行处理，低4位是数据，5~7位是指数，最高位是符号
        aval = seg << SEG_SHIFT;
        if (seg < 2)
            aval |= (pcm_val >> 1) & QUANT_MASK;
        else
            aval |= (pcm_val >> seg) & QUANT_MASK;
        return (aval ^ mask);
    }
}
 
int alaw2linear(int a_val)     
{
    int     t;      /* changed from "short" *drago* */
    int     seg;    /* changed from "short" *drago* */
  
    a_val ^= 0x55; //异或操作把mask还原
  
    t = (a_val & QUANT_MASK) << 4;//取低4位，即表中的abcd值，然后左移4位变成abcd0000
    seg = ((unsigned)a_val & SEG_MASK) >> SEG_SHIFT; //取中间3位，指数部分
    switch (seg) {
    case 0: //表中第一行，abcd0000 -> abcd1000
        t += 8;
        break;
    case 1: //表中第二行，abcd0000 -> 1abcd1000
        t += 0x108;
        break;
    default://表中其他行，abcd0000 -> 1abcd1000 的基础上继续左移(按照表格第二三列进行处理)
        t += 0x108;
        t <<= seg - 1;
    }
    return ((a_val & SIGN_BIT) ? t : -t);
}
```

##### 1.2.2 u-law

u-law输入的是14位，编码算法就是查表，计算出：基础值+平均偏移值

u-law的公式如下，μ取值一般为255

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E9%9F%B3%E9%A2%91%E8%A7%A3%E7%A0%81(c%E5%92%8CFFMpeg)3.png?raw=true)

计算方法如下表

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E9%9F%B3%E9%A2%91%E8%A7%A3%E7%A0%81(c%E5%92%8CFFMpeg)4.png?raw=true)

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E9%9F%B3%E9%A2%91%E8%A7%A3%E7%A0%81(c%E5%92%8CFFMpeg)5.png?raw=true)

输入pcm数据为1234

1. 取得范围值，查表得 `+2014 to +991 in 16 intervals of 64`
2. 得到基础值为0xA
3. 得到间隔数为64
4. 得到区间基本值2014
5. 当前值1234和区间基本值差异2014-1234=780
6. 偏移值=780/间隔数=780/64，取整得到12
7. 输出为0xA0+12=0xAC

c算法实现如下：

```
#define BIAS        (0x84)      /* Bias for linear code. 线性码偏移值*/
#define CLIP            8159    //最大量化级数量
  
int linear2ulaw( int    pcm_val)    /* 2's complement (16-bit range) */
{
    int     mask;
    int     seg;
    int     uval;
  
    /* Get the sign and the magnitude of the value. */
    pcm_val = pcm_val >> 2;
    if (pcm_val < 0) {
        pcm_val = -pcm_val;
        mask = 0x7F;
    } else {
        mask = 0xFF;
    }
        if ( pcm_val > CLIP ) pcm_val = CLIP;       /* clip the magnitude 削波*/
    pcm_val += (BIAS >> 2);
  
    /* Convert the scaled magnitude to segment number. */
    seg = search(pcm_val, seg_uend, 8);
  
    /*
     * Combine the sign, segment, quantization bits;
     * and complement the code word.
     */
    if (seg >= 8)       /* out of range, return maximum value. */
        return (0x7F ^ mask);
    else {
        uval = (seg << 4) | ((pcm_val >> (seg + 1)) & 0xF);
        return (uval ^ mask);
    }
  
}
  
int ulaw2linear( int    u_val)
{
    int t;
  
    /* Complement to obtain normal u-law value. */
    u_val = ~u_val;
  
    /*
     * Extract and bias the quantization bits. Then
     * shift up by the segment number and subtract out the bias.
     */
    t = ((u_val & QUANT_MASK) << 3) + BIAS;
    t <<= (u_val & SEG_MASK) >> SEG_SHIFT;
  
    return ((u_val & SIGN_BIT) ? (BIAS - t) : (t - BIAS));
}
```

#### 1.3 a-law和u-law的比较

a-law和u-law画在同一个坐标轴中就能发现A-law在低强度信号下，精度要稍微高一些。

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E9%9F%B3%E8%A7%86%E9%A2%91%E7%9B%B8%E5%85%B3/iOS%E9%9F%B3%E9%A2%91%E8%A7%A3%E7%A0%81(c%E5%92%8CFFMpeg)6.png?raw=true)

实际应用中，我们确实可以用浮点数计算的方式把F(x)结果计算出来，然后进行量化，但是这样一来计算量会比较大，实际上对于A-law（A=87.6时），是采用13折线近似的方式来计算的，而u-law（μ=255时）则是15段折线近似的方式。

### 2 解码实现流程代码和接口调用

#### 2.1 c算法实现

因为项目中可以直接使用c的代码，c算法的编解码的写法，已在上述1.2.1和1.2.2中写出。

生成一个类，将其上面的ulaw的算法封装调用即可。需要对压缩的buffer对每一位进行解码转换操作。因为压缩率是1:2，所以解码转换之后，长度要变为2倍。此项目中传输的长度是320，解码转换后长度是640。

解码后就是PCM的格式数据。

代码如下：

```
int G711UDecode(char* pRawData,const unsigned char* pBuffer, int nBufferSize) {
    short *out_data = (short*)pRawData;
    int i = 0;
    for(; i<nBufferSize; i++) {
        int v = ulaw2linear((unsigned char)pBuffer[i]);
        out_data[i] = v < -32768 ? -32768 : v > 32767 ? 32767 : v;
    }
     
    return nBufferSize * 2;
}
```

解码的时候，生成一个传输数据buffer的2倍长度的格式用来传入函数中即可。

```
short decodedBuffer[size * 2];
int bufferSize = G711Decode((char *)decodedBuffer, data, size);
```

#### 2.2 c算法编码

在1.2.1和1.2.2中，代码也包含了a-law和u-law的编码。

在项目中，对讲功能，需要麦克风收集到的PCM数据发送给设备时，传递的数据也需要是转换后的u-law格式。

同样的类中封装一个调用接口即可，编码需要传入pcm数据，同样的需要循环每一位进行编码转换。注意长度会缩短为一半，初始化长度的时候要注意。

代码如下：

```
void G711Encoder(void *pcm,unsigned char *code,int size,int lawflag) {
    short *input_data = (short *)pcm;
    int i;
    if(lawflag==0) {
        for(i=0;i<size;i++) {
            code[i]=linear2alaw(input_data[i]);
        }
    } else {
        for(i=0;i<size;i++) {
            code[i]=linear2ulaw(input_data[i]);
        }
    }
}
```

#### 2.3 FFmpeg音频解码

通过FFmpeg来实现音频编码仅需要调用几个接口接口。

类似视频解码。初始化的时候，先创建解码器配置和解码器上下文AVCodec和AVCodecContext，并开启解码器。其中要配置解码器上下文的音频参数，这里音频参数是采样率8K，16位，单声道。

```
codec = avcodec_find_decoder(AV_CODEC_ID_PCM_MULAW);
codecContext = avcodec_alloc_context3(codec);
 
// 配置上下文
codecContext->sample_fmt = AV_SAMPLE_FMT_S16;
codecContext->sample_rate = 8000;
codecContext->channels = 1;
 
avcodec_open2(codecContext, codec, nil);
```

然后使用AVPacket来组装原始的u-law数据

```
AVPacket *packet = av_packet_alloc();
av_new_packet(packet, size);
packet->size = size;
packet->pts = timestamp;
memcpy(packet->data, data, size);
[self decodeBufferWithPacket:packet];
av_packet_free(&packet);
```

再使用avcodec_send_packet和avcodec_receive_frame接口既可以解码出AVFrame，AVFrame中的data第0个元素即为解码后的PCM数据。其中AVFrame中的linesize第0个元素为解码后的长度，打印出来也是解码前的2倍。

代码如下：

```
int ret = avcodec_send_packet(codecContext, packet);
if (ret < 0) {
    return;
}
avFrame = av_frame_alloc();
int avcodecRet = 0;
while (avcodecRet >= 0) {
    avcodecRet = avcodec_receive_frame(codecContext, avFrame);
    if (avcodecRet == AVERROR(EAGAIN) || avcodecRet == AVERROR_EOF) {
        av_frame_free(&avFrame);
        return;
    }
    else if (avcodecRet < 0) {
        av_frame_free(&avFrame);
        return;
    }
    if ([self.delegate respondsToSelector:@selector(ffmpegAudioDecoder:renderedAudioBuffer:length:)]) {
        [self.delegate ffmpegAudioDecoder:self renderedAudioBuffer:avFrame->data[0] length:avFrame->linesize[0]];
    }
}
av_frame_free(&avFrame);
```

通过c算法和FFmpeg解码的效果和对内存CPU的消耗都差不多。