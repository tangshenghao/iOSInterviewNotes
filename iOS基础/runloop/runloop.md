## runloop

### 1 runloop概念

runloop是用来接收处理事件的循环。一个循环中，等待事件发生，然后将这个事件送到能处理它的地方。

处理的流程是 接收消息 -> 恢复活跃 -> 处理消息 -> 进入休眠。

#### 1.1 runloop作用

- 保持程序持续运行，程序一启动就会开一个主线程，主线程一开起来就会跑一个主线程对应的RunLoop，RunLoop保证主线程不会被销毁，也保证了程序的持续运行。
- 处理APP中的各种事件，（接触事件，定时器事件，Selector事件等）
- 节省CPU资源，提高性能。在没有事件处理的时候，进入睡眠模式，从而节省CPU资源，提高程序性能。

#### 1.2 runloop构成

从代码上看runloop是一个对象，也就是CFRunLoop对象。代码如下：

```
struct __CFRunLoop {
    CFRuntimeBase _base;
    pthread_mutex_t _lock;  /* locked for accessing mode list */
    __CFPort _wakeUpPort;   // used for CFRunLoopWakeUp 内核向该端口发送消息可以唤醒runloop
    Boolean _unused;
    volatile _per_run_data *_perRunData; // reset for runs of the run loop
    pthread_t _pthread;             //RunLoop对应的线程
    uint32_t _winthread;
    CFMutableSetRef _commonModes;    //存储的是字符串，记录所有标记为common的mode
    CFMutableSetRef _commonModeItems;//存储所有commonMode的item(source、timer、observer)
    CFRunLoopModeRef _currentMode;   //当前运行的mode
    CFMutableSetRef _modes;          //存储的是CFRunLoopModeRef
    struct _block_item *_blocks_head;//doblocks的时候用到
    struct _block_item *_blocks_tail;
    CFTypeRef _counterpart;
};
```

其中，主要是的对应的线程，若干个Mode，若干个commonMode，还有一个当前运行的Mode。

> CFRunLoop对象可以检测某个task或者dispatch的输入事件，当检测到有输入源事件，CFRunLoop将会将其加入到线程中进行处理。比方说用户输入事件、网络连接事件、周期性或者延时事件、异步的回调等。
>
> RunLoop可以检测的事件类型一共有3˙种，分别是CFRunLoopSource、CFRunLoopTimer、CFRunLoopObserver。可以通过CFRunLoopAddSrouce、CFRunLoopAddTimer或者CFRunLoopAddObserver添加碎影的事件类型。
>
> 要让一个RunLoop跑起来还需要run loop modes，每一个source，timer和observer添加到RunLoop中时必须要与一个模式（CFRunLoopMode）相关联才可以运行。

以上是官方文档的解释。

RunLoop的是由5个类来构成

```
CFRunLoopRef
 -CFRunLoopModeRef
   -CFRunLoopSourceRef
   -CFRunLoopTimerRef
   -CFRunLoopObserverRef
```

其中CFRunLoopRef的结构体内包含CFRunLoopModeRef。

然后CFRunLoopMode内包含着三种方式的事件类型的集合类型

```
struct __CFRunLoopMode {
    CFStringRef _name;            // Mode Name, 例如 @"kCFRunLoopDefaultMode"
    CFMutableSetRef _sources0;    // Set
    CFMutableSetRef _sources1;    // Set
    CFMutableArrayRef _observers; // Array
    CFMutableArrayRef _timers;    // Array
    ...
};
```



RunLoop的结构关系如图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/iOS%E5%9F%BA%E7%A1%80/runloop/runloop%E7%BB%93%E6%9E%84%E5%85%B3%E7%B3%BB.png?raw=true)



**CFRunLoopModeRef**

一个RunLoop包含了多个Mode，每个Mode又包含了若干个Source/Timer/Observer。每次调用RunLoop的主函数时，只能指定其中一个Mode，这个Mode被称作CurrentMode。如果需要切换Mode，只能退出Loop再重新指定一个Mode进入。这样做主要是为了分隔开不同Mode中的Source/Timer/Observer，让其互不影响。

一个CFRunLoopMode对象又一个name，若干个source0、source1、timer、observer和若干port，可见事件都是由Mode再管理，而RunLoop管理Mode。

Mode分为5个，分别是：

- NSDefaultRunLoopMode 

  -- App的默认Mode，通常主线程是在这个Mode下运行

- UIInitializationRunLoopMode

- GSEventReceiveRunLoopMode

  -- 接受系统时间的内部Mode，通常用不到

- NSEventTrackingRunLoopMode

  -- 界面跟踪Mode，用于ScrollView追踪触摸滑动，保证界面滑动时不受其他Mode影响。

- NSRunLoopCommonModes

  -- 一个占位用的Mode，不是一种真正的Mode

iOS中公开暴露出来的只有NSDefaultRunLoopMode和NSRunLoopCommonModes。NSRunLoopCommonModes实际上是一个Mode的集合，默认包括NSDefaultRunLoopMode和NSEventTrackingRunLoopMode。



**CFRunLoopSource**

RunLoopSource分为Source、Observer、Timer三种。

CFRunLoopSource是对input sources的抽象类，Source有两个版本：Source0和Source1。

- source0：只包含了一个回调，使用时，你需要先调用CFRunLoopSourceSignal(source)，将这个Source标记为待处理，然后手动调用CFRunLoopWakeUp(runloop)来唤醒RunLoop，让其处理这个事件。处理App内部事件，App自己负责管理，如UIEvent、CFSocketRef。

- source1： 由RunLoop和内核管理，由mach_port驱动，如CFMachPort、CFMessagePort、NSSocketPort。特别要注意一下machport的概念，它是一个轻量级的进程间通讯的方式，可以理解为它是一个通讯通道，假如同时有几个进程都挂在这个通道上，那么其他进程向这个通道发送消息后，这些挂在这个通道上的进程都可以收到相应的消息。它是RunLoop休眠和被唤醒的关键，是RunLoop和系统内核进行消息通讯的窗口。



**CFRunLoopTimerRef**

CFRunLoopTimerRef是基于时间的触发器，和NSTimer是toll-free bridged，可以相互转换。它受到Runloop的Mode影响，当其加入到RunLoop时，RunLoop会注册对应的时间点，当时间点到时，RunLoop会被唤醒以执行那个回调。如果线程阻塞或者不在这个Mode下，触发点将不会执行，一直等到下一个周期时间点触发。



**CFRunLoopObserverRef**

观察者，每个Observber都包含了一个回调，当RunLoop的状态发生变化时，观察者就能通过回调接受到这个变化，可以观测的时间点有以下几个：

```
enum CFRunLoopActivity {
    kCFRunLoopEntry              = (1 << 0),    // 即将进入Loop   
    kCFRunLoopBeforeTimers      = (1 << 1),    // 即将处理 Timer        
    kCFRunLoopBeforeSources     = (1 << 2),    // 即将处理 Source  
    kCFRunLoopBeforeWaiting     = (1 << 5),    // 即将进入休眠     
    kCFRunLoopAfterWaiting      = (1 << 6),    // 刚从休眠中唤醒   
    kCFRunLoopExit               = (1 << 7),    // 即将退出Loop  
    kCFRunLoopAllActivities     = 0x0FFFFFFFU  // 包含上面所有状态  
};
typedef enum CFRunLoopActivity CFRunLoopActivity;
```



timer和source1，可以反复使用，比如timer设置成repeat，port可以持续接收消息，而source0在一次触发后就会被runloop移除。

上述的三种被统称为mode item，一个item可以被同时加入多个mode中，但是一个item被重复加入同一个mode时是不会有效果的。如果一个mode中一个item都没有，那么RunLoop会直接退出，不进入循环。



#### 1.3 RunLoop运行机制

运行机制如下图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/iOS%E5%9F%BA%E7%A1%80/runloop/runloop%E8%BF%90%E8%A1%8C%E6%9C%BA%E5%88%B6.png?raw=true)



当调用CFRTunLoopRun()时，线程就会一直停留在这个循环里，直到超时或被手动停止，该函数才会返回。每次线程运行RunLoop都会自动处理之前未处理的消息，并且将消息发送给观察者，让事件得到执行。RunLoop运行时首先根据modeName找到对应mode，如果mode里没有source/timer/observer就会直接返回。



```
/// 用DefaultMode启动
void CFRunLoopRun(void) {
    CFRunLoopRunSpecific(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 1.0e10, false);
}
 
/// 用指定的Mode启动，允许设置RunLoop超时时间
int CFRunLoopRunInMode(CFStringRef modeName, CFTimeInterval seconds, Boolean stopAfterHandle) {
    return CFRunLoopRunSpecific(CFRunLoopGetCurrent(), modeName, seconds, returnAfterSourceHandled);
}
 
/// RunLoop的实现
int CFRunLoopRunSpecific(runloop, modeName, seconds, stopAfterHandle) {
    
    /// 首先根据modeName找到对应mode
    CFRunLoopModeRef currentMode = __CFRunLoopFindMode(runloop, modeName, false);
    /// 如果mode里没有source/timer/observer, 直接返回。
    if (__CFRunLoopModeIsEmpty(currentMode)) return;
    
    /// 1. 通知 Observers: RunLoop 即将进入 loop。
    __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopEntry);
    
    /// 内部函数，进入loop
    __CFRunLoopRun(runloop, currentMode, seconds, returnAfterSourceHandled) {
        
        Boolean sourceHandledThisLoop = NO;
        int retVal = 0;
        do {
 
            /// 2. 通知 Observers: RunLoop 即将触发 Timer 回调。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeTimers);
            /// 3. 通知 Observers: RunLoop 即将触发 Source0 (非port) 回调。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeSources);
            /// 执行被加入的block
            __CFRunLoopDoBlocks(runloop, currentMode);
            
            /// 4. RunLoop 触发 Source0 (非port) 回调。
            sourceHandledThisLoop = __CFRunLoopDoSources0(runloop, currentMode, stopAfterHandle);
            /// 执行被加入的block
            __CFRunLoopDoBlocks(runloop, currentMode);
 
            /// 5. 如果有 Source1 (基于port) 处于 ready 状态，直接处理这个 Source1 然后跳转去处理消息。
            if (__Source0DidDispatchPortLastTime) {
                Boolean hasMsg = __CFRunLoopServiceMachPort(dispatchPort, &msg)
                if (hasMsg) goto handle_msg;
            }
            
            /// 通知 Observers: RunLoop 的线程即将进入休眠(sleep)。
            if (!sourceHandledThisLoop) {
                __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeWaiting);
            }
            
            /// 7. 调用 mach_msg 等待接受 mach_port 的消息。线程将进入休眠, 直到被下面某一个事件唤醒。
            /// • 一个基于 port 的Source 的事件。
            /// • 一个 Timer 到时间了
            /// • RunLoop 自身的超时时间到了
            /// • 被其他什么调用者手动唤醒
            __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort) {
                mach_msg(msg, MACH_RCV_MSG, port); // thread wait for receive msg
            }
 
            /// 8. 通知 Observers: RunLoop 的线程刚刚被唤醒了。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopAfterWaiting);
            
            /// 收到消息，处理消息。
            handle_msg:
 
            /// 9.1 如果一个 Timer 到时间了，触发这个Timer的回调。
            if (msg_is_timer) {
                __CFRunLoopDoTimers(runloop, currentMode, mach_absolute_time())
            } 
 
            /// 9.2 如果有dispatch到main_queue的block，执行block。
            else if (msg_is_dispatch) {
                __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
            } 
 
            /// 9.3 如果一个 Source1 (基于port) 发出事件了，处理这个事件
            else {
                CFRunLoopSourceRef source1 = __CFRunLoopModeFindSourceForMachPort(runloop, currentMode, livePort);
                sourceHandledThisLoop = __CFRunLoopDoSource1(runloop, currentMode, source1, msg);
                if (sourceHandledThisLoop) {
                    mach_msg(reply, MACH_SEND_MSG, reply);
                }
            }
            
            /// 执行加入到Loop的block
            __CFRunLoopDoBlocks(runloop, currentMode);
            
 
            if (sourceHandledThisLoop && stopAfterHandle) {
                /// 进入loop时参数说处理完事件就返回。
                retVal = kCFRunLoopRunHandledSource;
            } else if (timeout) {
                /// 超出传入参数标记的超时时间了
                retVal = kCFRunLoopRunTimedOut;
            } else if (__CFRunLoopIsStopped(runloop)) {
                /// 被外部调用者强制停止了
                retVal = kCFRunLoopRunStopped;
            } else if (__CFRunLoopModeIsEmpty(runloop, currentMode)) {
                /// source/timer/observer一个都没有了
                retVal = kCFRunLoopRunFinished;
            }
            
            /// 如果没超时，mode里没空，loop也没被停止，那继续loop。
        } while (retVal == 0);
    }
    
    /// 10. 通知 Observers: RunLoop 即将退出。
    __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);
} 
```



#### 1.4 RunLoop挂起和唤醒

**RunLoop挂起**

runloop的挂起是通过CFRunLoopServiceMachPort-call -> mach_msg-call -> mach_msg_trap这个调用顺序来告诉内核RunLoop监听哪个mach_port(上面提到的消息通道)，然后等待事件的发生，InputSource或Timer相关的事件，这个内核就把RunLoop挂起了，休眠模式。



**RunLoop唤醒**

以下几种情况下会被唤醒

- 存在Source0被标记为待处理，系统调用CFRunLoopWakeUp唤醒线程处理
- 定时器时间到了
- RunLoop自身的超时时间到了
- RunLoop外部调用者唤醒

当RunLoop被挂起后，如果之前监听的事件发生了，由另一个线程向内核发送这个mach_port的msg后，trap状态被唤醒，RunLoop继续运行



#### 1.5 处理事件

- 如果一个Timer到事件了，触发这个Timer的回调
- 如果有dispatch到main_queue的block，执行block
- 如果有一个Source1发出事件了，处理这个事件

事件处理完成进行判断

进入loop时传入参数指明处理完事件就返回 stopAfterHandle

超出传入参数标记的超时时间 timeout

被外部调用者强制停止  __CFRunLoopIsStopped(runloop)

source/timer/observer全都空了 __CFRunLoopModelsEmpty(runloop, currentMode)



### 2 runloop的底层实现

为了实现消息的发送和接收，mach_msg()函数实际上是调用了一个Mach陷阱(trap)，即函数mach_msg_trap()，陷阱这个概念在Mach中等同于系统调用。当你在用户态调用mach_msg_trap()时会触发陷阱机制，切换到内核状态。内核态中内核实现的mach_msg()函数会完成实际的工作，如下图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/iOS%E5%9F%BA%E7%A1%80/runloop/runloop%E6%B6%88%E6%81%AF%E5%8E%9F%E7%90%86.png?raw=true)

RunLoop的核心就是一个mach_msg()，RunLoop调用这个函数去接收消息，如果没有别人发送port消息过来，内核会将线程置于等待状态，例如你在模拟器跑一个App，在静止状态点击暂停，你会看到主线程调用的栈停留在mach_msg_trap()这个地方。



### 3 runloop和线程

RunLoop和线程是一一对应的，正常情况下，线程在执行一个或多个任务后就会退出，不能再执行任务了，这时我们就需要采用一个种方式来让线程能够处理任务，并不退出。所以RunLoop起到了作用。

两个线程对象NSThread和pthread_t是一一对应的。比如，可以通过pthread_main_thread_np()或[NSThread mainThread]来获取主线程，也可以通过pthread_self()或[NSThread currentThread]来获取当前线程。CFRunLoop是基于pthread来管理的。

线程和RunLoop的对应关系保存在一个全局的Dictionary里，线程创建之后是没有runLoop的，主线程除外。RunLoop的创建是在发生第一次获取时，销毁则是在线程结束的时候。只能在当前线程中操作当前线程的RunLoop，不能跨线程操作。不允许直接创建RunLoop，可以通过获取，获取的时候如果没有，系统会自动创建。

获取的代码如下：

```
/// 全局的Dictionary，key 是 pthread_t， value 是 CFRunLoopRef
static CFMutableDictionaryRef loopsDic;
/// 访问 loopsDic 时的锁
static CFSpinLock_t loopsLock;
 
/// 获取一个 pthread 对应的 RunLoop。
CFRunLoopRef _CFRunLoopGet(pthread_t thread) {
    OSSpinLockLock(&loopsLock);
    
    if (!loopsDic) {
        // 第一次进入时，初始化全局Dic，并先为主线程创建一个 RunLoop。
        loopsDic = CFDictionaryCreateMutable();
        CFRunLoopRef mainLoop = _CFRunLoopCreate();
        CFDictionarySetValue(loopsDic, pthread_main_thread_np(), mainLoop);
    }
    
    /// 直接从 Dictionary 里获取。
    CFRunLoopRef loop = CFDictionaryGetValue(loopsDic, thread));
    
    if (!loop) {
        /// 取不到时，创建一个
        loop = _CFRunLoopCreate();
        CFDictionarySetValue(loopsDic, thread, loop);
        /// 注册一个回调，当线程销毁时，顺便也销毁其对应的 RunLoop。
        _CFSetTSD(..., thread, loop, __CFFinalizeRunLoop);
    }
    
    OSSpinLockUnLock(&loopsLock);
    return loop;
}
 
CFRunLoopRef CFRunLoopGetMain() {
    return _CFRunLoopGet(pthread_main_thread_np());
}
 
CFRunLoopRef CFRunLoopGetCurrent() {
    return _CFRunLoopGet(pthread_self());
}
```

调用[NSTimer scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:]该方法时，会创建Timer并把Timer放到当前线程的RunLoop中，随后RunLoop会在Timer设定的时间点回调Timer绑定的Selector或Invocation。但是主线程和子线程调用时是不一样的，主线程因为已经创建好了RunLoop并且一直运行着，所以可以有回调，而子线程没有创建RunLoop且没有启动，所以不能触发。

```
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(doTimer) userInfo:nil repeats:NO];
  [[NSRunLoop currentRunLoop] run];
});

那为什么下面这样调用同样不会触发Timer呢？
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
  [[NSRunLoop currentRunLoop] run];
  [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(doTimer) userInfo:nil repeats:NO];
});  
```

scheduledTimerWithTimeInterval内部在向RunLoop传递Timer时是调用与线程实例相关的单例方法[NSRunLoop currentRunLoop]来获取RunLoop实例，而在RunLoop开始运行后再向其传递Timer时，由于dispatch_async代码块内的两行代码时顺序执行，[[NSRunLoop currentRunLoop] run];是一个没有结束时间的RunLoop，无法执行到scheduledTimerWithTimeInterval这一行代码，Timer也就没有被加到当前RunLoop中，所以更不会触发Timer。



### 4 runloop实现的功能

#### 4.1 AutoreleasePool

App启动之后，系统启动主线程并创建了RunLoop，在main thread中注册了两个observer，回调都是_warpRunLoopWithAutoreleasePoolhandle()

第一个Observer监听一个事件

1. 即将进入Loop（KCFRunLoopEntry），其回调内会调用 _objc_autoreleasePoolPush()创建自动释放池。其orser是-214783647，优先级最高，保证创建释放池发生在其他所有回调之前。

第二个Observer监听两个事件

1. 准备进入休眠，此时调用objc_autoreleasePoolPop()和objc_autoreleasePoolPush()来释放旧的池并创建新的池
2. 即将退出Loop时调用objc_autoreleasePoolPop()释放自动释放池。这个Observer的ordfer是214783647，确保自动释放池释放在所有回调之后。



#### 4.2 NSTimer

上文中说的CFRunLoopTimerRef，其实NSTimer的原型就是CFRunLoopTimerRef。一个Timer注册RunLoop之后，RunLoop会为这个Timer的重复时间点注册好事件，有两点需要注意：

- RunLoop为了节省资源，并不会在非常准确的时间点回调这个Timer。Timer有个属性叫做Tolerance宽容度，偏差度。标示了当时间点到后，容许的最大偏差。这个偏差默认为0，可以手动设置误差。无论设置值是多少，当前线程并不阻塞，系统依旧可能为在NSTimer上加上很小的容差。
- 在哪个线程调用NSRTimer，就必须在哪个线程终止。

还有RunLoop的Mode中也需要注意，在开发NSTimer实现图片轮播时，需要设置Mode为commonModes，不然会在滑动时，会停止轮播。



#### 4.3 和GCD的关系

RunLoop底层用到GCD

RunLoop与GCD并没有直接关系，但当GCD使用到main_queue时才有关系，如下：

```objectivec
//实验GCD Timer 与 Runloop的关系，只有当dispatch_get_main_queue时才与RunLoop有关系
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    NSLog(@"GCD Timer...");
});
```

主线程的情况下，libDispatch会向主线程RunLoop发送消息，RunLoop会唤醒，并从消息中取得这个block，然后在回调中执行block。dispatch到其他线程仍然是libDispatch处理的，同理，GCD的dispatch_after在dispatch到main_queue时的timer机制才与RunLoop相关。



#### 4.4 PerformSelecter

NSObject的PerformSelecter:afterDelay:实际上其内部会创建一个Timer并添加到当前线程的RunLoop中，所以如果当前线程没有RunLoop，则这个方法会失效。



#### 4.5 事件响应

苹果注册了一个Source1（基于mach port）用来接收系统事件，其回调函数是__IOHIDEventSystemClientQueueCallback()。

当一个事件，触摸/锁屏/摇晃等，首先先由IOKit.framework生成一个IOHIDEvent事件并由SpringBoard接收。随后用mach port转发给需要的App进程。

_UIApplicationHandleEventQueue()会把IOHIDEvent处理并包装成UIEvent进行处理或分发，其中包括识别UIGesture/处理屏幕/发送给UIWindow等。



#### 4.6 手势识别

当上面的_UIApplicationHandleEventQueue()识别了一个手势时，其首先会调用Cancel将当前的touchesBegin/Move/End系列回调打断。随后系统将对应的UIGestureRecognizer标记为待处理。

苹果注册了一个Observer监测BeforeWaiting事件，即将进入休眠。这个Observer的回调函数时 _UIGestureRecognizerUpdateObserver()，其内部会获取所有刚被标记待处理的GestureRecognizer，并执行回调。

当有UIGestureRecognizer的变化时，这个回调都会进行响应处理。



#### 4.7 UI更新

Core Animation会在RunLoop中注册Observer监听即将进入休眠和即将退出休眠的事件。触发更新时，会将UIView/CALayer标记为待处理，并被提交到一个全局的容器去。当监听的事件来时，就会去遍历所有待处理的UIView/CALayer以执行实际的绘制和调整，更新UI页面。

如果有动画，通过DisplayLink稳定的刷新机制不断唤醒runloop。

> CADisplayLink是一个执行频率和屏幕刷新相同的定时器，需要加入runloop才能执行，与NSTimer类似，同样也是基于CFRunloopTimerRef实现，底层使用mk_timer(可以比较加入到RunLoop前后RunLoop中timer的变化)。和NSTimer相比精度更高，不过和NSTimer类似的是如果遇到大任务它仍然存在丢帧现象。通常情况下CADisplayLink用于构建帧动画，看起来相对更加流畅，而NSTimer则有更多的用处

YYFPSLabel就是以CADisplayLink的特性来实现的，使用CADisplayLink的timestamp配合timer的执行次数计算得出FPS的数字。