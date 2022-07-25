## Crash

### 1 Crash的类型

- Mach异常

最底层的内核级异常，用户态的开发者可以直接通过Mach API设置thread，task，host的异常端口来捕获Mach异常。

- Unit信号

又称BSD信号，如果开发者没有捕获Mach异常，则会被host层的方法ux_exception()将异常转换为对应的UNIX信号，并通过方法threadsignal()将信号投递到出错线程，可以通过方法signal(x, SignalHandler)来捕获signal。

- NSException

应用级异常，它是未被捕获的Objective-C异常，导致程序向自身发送了SIGABRT信号而崩溃，是app自己可控的，对于未捕获的OC异常，可以通过try catch来捕获或者通过NSSetUncaughtExceptionHandler()机制来捕获。

<br />

#### 1.1 Mach异常

##### 1.1.1 Mach内核抽象

tasks

资源所有权单位，每个任务由一个虚拟地址空间、一个端口权限名称空间和一个或多个线程组成。（类似于进程）

threads

任务中CPU执行的单位。

ports

安全的单工通信通道，只能通过发送和接收功能（端口权限）进行访问。

上述这些内核对象，对于Mach来说都是一个个的Object，这些Objects基于Mach实现自己的功能，并通过Mach Message来进行通信，Mach提供了相关的应用层的API来操作，与Mach异常相关的几个API有：

task_get_exception_ports：获取task的异常端口

task_set_exception_ports：设置task的异常端口

mach_port_allocate：创建调用者指定的端口权限类型

mach_port_insert_right：将指定的端口插入目标task

<br />

##### 1.1.2 如果捕获Mach异常

捕获方式如下图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E6%80%A7%E8%83%BD%E6%B2%BB%E7%90%86/Crash/crash1.png?raw=true)

主要的流程是：新建一个监控线程，在监控线程中监听Mach异常并处理异常信息，步骤如下图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E6%80%A7%E8%83%BD%E6%B2%BB%E7%90%86/Crash/crash2.png?raw=true)

具体代码如下：

```
static mach_port_t server_port;
static void *exc_handler(void *ignored);

//判断是否 Xcode 联调
bool ksdebug_isBeingTraced(void)
{
    struct kinfo_proc procInfo;
    size_t structSize = sizeof(procInfo);
    int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};
    
    if(sysctl(mib, sizeof(mib)/sizeof(*mib), &procInfo, &structSize, NULL, 0) != 0)
    {
        return false;
    }
    
    return (procInfo.kp_proc.p_flag & P_TRACED) != 0;
}

#define EXC_UNIX_BAD_SYSCALL 0x10000 /* SIGSYS */
#define EXC_UNIX_BAD_PIPE    0x10001 /* SIGPIPE */
#define EXC_UNIX_ABORT       0x10002 /* SIGABRT */
static int signalForMachException(exception_type_t exception, mach_exception_code_t code)
{
    switch(exception)
    {
        case EXC_ARITHMETIC:
            return SIGFPE;
        case EXC_BAD_ACCESS:
            return code == KERN_INVALID_ADDRESS ? SIGSEGV : SIGBUS;
        case EXC_BAD_INSTRUCTION:
            return SIGILL;
        case EXC_BREAKPOINT:
            return SIGTRAP;
        case EXC_EMULATION:
            return SIGEMT;
        case EXC_SOFTWARE:
        {
            switch (code)
            {
                case EXC_UNIX_BAD_SYSCALL:
                    return SIGSYS;
                case EXC_UNIX_BAD_PIPE:
                    return SIGPIPE;
                case EXC_UNIX_ABORT:
                    return SIGABRT;
                case EXC_SOFT_SIGNAL:
                    return SIGKILL;
            }
            break;
        }
    }
    return 0;
}

static NSString *stringForMachException(exception_type_t exception) {
    switch(exception)
    {
        case EXC_ARITHMETIC:
            return @"EXC_ARITHMETIC";
        case EXC_BAD_ACCESS:
            return @"EXC_BAD_ACCESS";
        case EXC_BAD_INSTRUCTION:
            return @"EXC_BAD_INSTRUCTION";
        case EXC_BREAKPOINT:
            return @"EXC_BREAKPOINT";
        case EXC_EMULATION:
            return @"EXC_EMULATION";
        case EXC_SOFTWARE:
        {
            return @"EXC_SOFTWARE";
            break;
        }
    }
    return 0;
}

void installExceptionHandler() {
    if (ksdebug_isBeingTraced()) {
        // 当前正在调试状态, 不启动 mach 监听
        return ;
    }
    kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &server_port);
    assert(kr == KERN_SUCCESS);
    
    kern_return_t rc = 0;
    exception_mask_t excMask = EXC_MASK_BAD_ACCESS |
    EXC_MASK_BAD_INSTRUCTION |
    EXC_MASK_ARITHMETIC |
    EXC_MASK_SOFTWARE |
    EXC_MASK_BREAKPOINT;
    
    rc = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &server_port);
    if (rc != KERN_SUCCESS) {
        fprintf(stderr, "------->Fail to allocate exception port\\\\\\\\n");
        return;
    }
    
    rc = mach_port_insert_right(mach_task_self(), server_port, server_port, MACH_MSG_TYPE_MAKE_SEND);
    if (rc != KERN_SUCCESS) {
        fprintf(stderr, "-------->Fail to insert right");
        return;
    }
    
    rc = thread_set_exception_ports(mach_thread_self(), excMask, server_port, EXCEPTION_DEFAULT, MACHINE_THREAD_STATE);
    if (rc != KERN_SUCCESS) {
        fprintf(stderr, "-------->Fail to  set exception\\\\\\\\n");
        return;
    }
    
    //建立监听线程
    pthread_t thread;
    pthread_create(&thread, NULL, exc_handler, NULL);
}

static void *exc_handler(void *ignored) {
    // Exception handler – runs a message loop. Refactored into a standalone function
    // so as to allow easy insertion into a thread (can be in same program or different)
    mach_msg_return_t rc;
    fprintf(stderr, "Exc handler listening\\\\\\\\n");
    // The exception message, straight from mach/exc.defs (following MIG processing) // copied here for ease of reference.
    typedef struct {
        mach_msg_header_t Head;
        /* start of the kernel processed data */
        mach_msg_body_t msgh_body;
        mach_msg_port_descriptor_t thread;
        mach_msg_port_descriptor_t task;
        /* end of the kernel processed data */
        NDR_record_t NDR;
        exception_type_t exception;
        mach_msg_type_number_t codeCnt;
        integer_t code[2];
        int flavor;
        mach_msg_type_number_t old_stateCnt;
        natural_t old_state[144];
    } Request;
    
    Request exc;

    struct rep_msg {
        mach_msg_header_t Head;
        NDR_record_t NDR;
        kern_return_t RetCode;
    } rep_msg;
    
    for(;;) {
        // Message Loop: Block indefinitely until we get a message, which has to be
        // 这里会阻塞，直到接收到exception message，或者线程被中断。
        // an exception message (nothing else arrives on an exception port)
        rc = mach_msg( &exc.Head,
                      MACH_RCV_MSG|MACH_RCV_LARGE,
                      0,
                      sizeof(Request),
                      server_port, // Remember this was global – that's why.
                      MACH_MSG_TIMEOUT_NONE,
                      MACH_PORT_NULL);
        
        if(rc != MACH_MSG_SUCCESS) {
            /*... */
            break ;
        };
        
        //Mach Exception 类型
        NSMutableString *crashInfo = [NSMutableString stringWithFormat:@"mach exception:%@ %@\n\n",stringForMachException(exc.exception), stringForSignal(signalForMachException(exc.exception, exc.code[0]))];
        
        rep_msg.Head = exc.Head;
        rep_msg.NDR = exc.NDR;
        rep_msg.RetCode = KERN_FAILURE;
        
        kern_return_t result;
        if (rc == MACH_MSG_SUCCESS) {
            result = mach_msg(&rep_msg.Head,
                              MACH_SEND_MSG,
                              sizeof (rep_msg),
                              0,
                              MACH_PORT_NULL,
                              MACH_MSG_TIMEOUT_NONE,
                              MACH_PORT_NULL);
        }
        //移除其他 Crash 监听, 防止死锁
        NSSetUncaughtExceptionHandler(NULL);
        signal(SIGHUP, SIG_DFL);
        signal(SIGINT, SIG_DFL);
        signal(SIGQUIT, SIG_DFL);
        signal(SIGABRT, SIG_DFL);
        signal(SIGILL, SIG_DFL);
        signal(SIGSEGV, SIG_DFL);
        signal(SIGFPE, SIG_DFL);
        signal(SIGBUS, SIG_DFL);
        signal(SIGPIPE, SIG_DFL);
    }
    
    return  NULL;
}
```

需要注意：

避免在Xcode联调时监听，因为监听了类型的Exception，一旦启动app联调后，会立即触发EXC_BREAKPOINT，而这段代码处理完之后，会进入下一个循环等待，主线程也会等待消息处理结果，会造成死锁。

<br />

#### 1.2 Unit信号

Unix Signal其实是由Mach port抛出的信号转化。

##### 1.2.1 信号类型

**SIGHUP**

用户终端连接（正常或非正常）结束时发出，通常是在终端的控制进程结束时，通知同一session内的各个作业，这时它们与控制终端不再关联。

**SIGINT**

程序终止（interrupt）信号，在用户键入INTR字符（通常是Ctrl-C）时发出，用于通知前台进程组终止进程。

**SIGQUIT**

和SIGINT类似，但由QUIT字符（通常是Ctrl-）来控制，进程在收到SIGQUIT退出时产生core文件，在这个意义上类似于一个程序错误信号。

**SIGABRT**

调用abort函数生成的信号

**SIGBUS**

非法地址，包括内存地址对齐出错。比如访问四个字节长度的整数，但其地址不是4的倍数。与SIGSEGV的区别在于后者是由于对合法存储地址的非法访问触发的（如访问不属于自己存储空间或只读存储空间）。

**SIGFPE**

发生致命的算术运算错误时发出，不仅包括浮点运算错误，还包括溢出及除数为0等其他所有的算术错误。

**SIGKILL**

用来立即结束程序的运行，本信号不能被阻塞、处理和忽略。如果某个进程终止不了，可尝试发送这个信号。

**SIGSEGV**

试图访问未分配给自己的内存或试图往没有写权限的内存地址写数据。

**SIGPIPE**

管道破裂，信号通常在进程间通信产生，比如采用队列通信的两个进程，读管道没打开或者终止就往管道写，写进程会收到该信号。

**SIGSYS**

非法的系统调用。

**SIGTRAP**

由断点指令或其他trap指令产生，由调试人员使用。

**SIGILL**

执行了非法指令，通常是因为可执行文件本身出现错误，或者试图执行数据段，堆栈溢出时也有可能产生这个信号。

可以参考[linux各个SIG信号含义](https://blog.csdn.net/weixin_42568866/article/details/89485722)

<br />

##### 1.2.2 捕捉Unix信号

实现代码如下：

```
static const int g_fatalSignals[] =
{
    SIGABRT,
    SIGBUS,
    SIGFPE,
    SIGILL,
    SIGPIPE,
    SIGSEGV,
    SIGSYS,
    SIGTRAP,
};

void installSignalHandler() {
        signal(SIGABRT, handleSignalException);
    // ...等等其他需要监听的 Signal
}
void handleSignalException(int signal) {
    //打印堆栈
    NSMutableString * crashInfo = [[NSMutableString alloc]init];
    [crashInfo appendString:[NSString stringWithFormat:@"signal:%d\n",signal]];
    [crashInfo appendString:@"Stack:\n"];
    void* callstack[128];
    int i, frames = backtrace(callstack, 128);
    char** strs = backtrace_symbols(callstack, frames);
    for (i = 0; i <frames; ++i) {
        [crashInfo appendFormat:@"%s\n", strs[I]];
    }
    NSLog(@"%@", crashInfo);
    //移除其他 Crash 监听, 防止死锁
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGHUP, SIG_DFL);
    signal(SIGINT, SIG_DFL);
    signal(SIGQUIT, SIG_DFL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
}
```

<br />

##### 1.2.3 备用信号栈

上面这个方法可以监控到大部分的Signal异常，但是如果遇到死循环这类的crash，就没法监控了，原因是一般情况下，信号处理函数被调用时，内核会在进程的栈上为其创建一个栈帧，会有一个问题时，如果之前栈的增长达到了最大长度，或者差点达到，会导致信号处理函数不能得到足够的栈帧分配。

为了解决这个问题，需要设定一个可选的栈帧：

1. 申请一块内存空间作为可选的信号处理函数栈使用
2. 使用sigaltstack函数通知系统可选的信号处理栈的存在及其位置
3. 当使用sigaction函数建立一个信号处理函数时，通过制定SA_ONSTACK标志通知系统这个信号处理函数应该在可选的栈上面执行注册的信号处理函数。

代码如下：

```
void installSignalHandler() {
        stack_t ss;
    struct sigaction sa;
    struct timespec req, rem;
    long ret;

    ss.ss_flags = 0;
    ss.ss_size = SIGSTKSZ;
    ss.ss_sp = malloc(ss.ss_size);
    sigaltstack(&ss, NULL);

    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handleSignalException;
    sa.sa_flags = SA_ONSTACK;
    sigaction(SIGABRT, &sa, NULL);
}
```

 <br />

#### 1.3 NSException

NSException是应用级异常，是指OC代码运行过程由Objective-C抛出的异常，基本上是代码运行过程中的逻辑错误，比如NSArray中插入nil对象，或者用nil初始化NSURL等，最简单区分一个异常是否NSException的方式是看这个异常能否被try-catch给捕获。

##### 1.3.1 常见的NSException类型

**NSInvalidArgumentException**

非法参数异常是OC代码最常出现的错误，传入非法参数导致异常，其中传入nil最为常见。

**NSRangeException**

越界异常

**NSGenericException**

最容易出现在循环操作，在for in循环中如果修改了遍历的数组，就会出错。

**NSInternalInconsistencyException**

不一致导致的异常，比如NSDictionary当作NSMutableDictionary来使用，从他们内部的机理来说，就会产生一些错误。

```
NSMutableDictionary *info = method return to NSDictionary type;
[info setObject:@“sxm” forKey:@”name”];
```

**NSFileHandleOperationException**

处理文件时的一些异常，最常见的还是存储空间不足的问题，比如应用频繁的保存文档，缓存资料或者处理比较大的数据。

**NSMallocException**

这也是内存不足的问题，无法分配足够的内存空间。

**KVO Crash**

移除未注册的观察者
重复移除观察者
添加了观察者但是没有实现`-observeValueForKeyPath:ofObject:change:context:`方法

**unrecognized selector send to instance**

调用方法未找到

<br />

##### 1.3.2 监听NSException异常

代码实现如下：

```
void InstallUncaughtExceptionHandler(void) {
    NSSetUncaughtExceptionHandler( &handleUncaughtException );
}

void handleUncaughtException(NSException *exception) {
    NSString * crashInfo = [NSString stringWithFormat:@"yyyy Exception name：%@\nException reason：%@\nException stack：%@",[exception name], [exception reason], [exception callStackSymbols]];
    NSLog(@"%@", crashInfo);
}
```

需要注意的是，在监听处理的方法中，是无法直接采集错误堆栈的。

<br />

#### 1.4 C++异常

除了上述三种类型的crash，还有C++异常需要捕捉，实际上也可以通过Mach异常的方式处理，只是处理细节上有区别。

系统在捕捉到C++异常后，如果能够将此C++异常转换为OC异常，则抛出OC异常处理机制；如果不能转换，则会立即调用`__cxa_throw`重新抛出异常。

如果不能转换为OC异常时，上层捕获的调用堆栈是RunLoop异常处理函数的堆栈，导致原始异常调用栈丢失。

```
Thread 0 Crashed:: Dispatch queue: com.apple.main-thread
0   libsystem_kernel.dylib          0x00007fff93ef8d46 __kill + 10
1   libsystem_c.dylib               0x00007fff89968df0 abort + 177
2   libc++abi.dylib                 0x00007fff8beb5a17 abort_message + 257
3   libc++abi.dylib                 0x00007fff8beb33c6 default_terminate() + 28
4   libobjc.A.dylib                 0x00007fff8a196887 _objc_terminate() + 111
5   libc++abi.dylib                 0x00007fff8beb33f5 safe_handler_caller(void (*)()) + 8
6   libc++abi.dylib                 0x00007fff8beb3450 std::terminate() + 16
7   libc++abi.dylib                 0x00007fff8beb45b7 __cxa_throw + 111
8   test                            0x0000000102999f3b main + 75
9   libdyld.dylib                   0x00007fff8e4ab7e1 start + 1
```

##### 1.4.1 捕获C++异常

为了获取C++异常的调用堆栈，需要模拟抛出NSException的过程并在此过程中保存调用栈。

1. 设置异常处理函数

```
g_originalTerminateHandler = std::set_terminate(CPPExceptionTerminate);
```

2. 重写`__cxa_throw`

```
void __cxa_throw(void* thrown_exception, std::type_info* tinfo, void (*dest)(void*))
```

3. 异常处理函数

`__cxa_throw`往后执行，进入set_terminate设置的异常处理函数，判断如果检测是OC异常，则不处理，否则获取异常信息。

<br />

### 2 Crash的处理顺序

如下图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E6%80%A7%E8%83%BD%E6%B2%BB%E7%90%86/Crash/crash3.png?raw=true)

1. 如果是NSException类型的异常

先看是否有被try-catch，再看有没有实现NSSetUncaughtExceptionHandler。最后如果都没处理，则调用c的abort()，kernal针对app发出_pthread_kill 的信号，转为Mach异常。

2. 如果是Mach异常

app如果处理了mach异常则进入处理流程，否则mach异常会被转为Unix/BSD signal信号，并进入Signal的处理流程

过程就是NSException -> Mach -> Signal

<br />

#### 2.1 不同类型异常的关系和处理决策

首先要明确的一点是，Mach异常和UNIX信号都可以被捕获，他们几乎一一对应，那么为什么所有的Crash监控框架都会捕获Mach异常、Unix信号以及NSException呢？

##### 2.1.1 Mach异常和Unix信号

所有Mach异常未处理，它将在host层被ux_exception转换为相应的Unix信号，并通过threadsignal将信号投递到出错的线程，所以其实我们看到的Unix信号异常，都是从Mach传过来的，只是在Mach没有catch，所以转成Unix来处理，比如Bad Access。

1. **既然Unix信号都是由Mach Exception转化的，为啥还要转Unix信号呢，直接传Mach的异常不就行了？**

   这是为了兼容更流行的POSIX标准，BSD在Mach异常机制之上构建的UNIX信号处理机制。

2. **既然Mach Exception能转化为Signal信号，Signal信号监听也更简单，为什么不只监听Signal信号？**

   不是所有的“Mach 异常”类型都映射到了“Unix 信号”。如EXC_GUARD。在苹果开源的xnu源码中可以看到。

3. **为什么优先监听Mach Exception？**

   这是因为Mach异常会更早的抛出来，而且如果Mach异常的handle让程序exit了，那么Unix信号就永远不会到达这个进程了。

<br />

##### 2.1.2 为什么不能只监听Mach Exception

进程中监听Mach Exception，在EXC_Crash发生的时候，表示进程非正常退出，任何其他任务都不会被执行，所以Mach Exception handler不会执行。类似abort()的方法只会触发signal信号，不会触发hardware trap，所以需要监听Signal信号。

<br />

##### 2.1.3 Mach Exception和Signal的转换关系

| **signal** | **exception type**   |
| ---------- | -------------------- |
| SIGFPE     | EXC_ARITHMETIC       |
| SIGSEGV    | EXC_BAD_ACCESS       |
| SIGBUS     | EXC_BAD_ACCESS       |
| SIGILL     | EXC_BAD_INSTRUCTION  |
| SIGTRAP    | EXC_BREAKPOINT       |
| SIGEMT     | EXC_EMULATION        |
| SIGSYS     | EXC_UNIX_BAD_SYSCALL |
| SIGPIPE    | EXC_UNIX_BAD_PIPE    |
| SIGABRT    | EXC_CRASH            |
| SIGKILL    | EXC_SOFT_SIGNAL      |

<br />

##### 2.1.4 为什么要实现NSException监听

前面所说，通过Mach/Signal已经可以监听大部分的崩溃场景了，那为何我们还要实现NSException监听呢？原因是未被try-catch的NSException会发出kill或者pthread_kill信号->Mach异常->Unix信号（SIGABRT），但是SIGABRT在处理信息时，获取不到当前的堆栈，所以采用NSSetUncaughtExceptionHandler。

<br />

### 3 捕获Swift崩溃

swift通常都是通过对应的signal来捕获crash，对于swift崩溃捕获，Apple的文档描述如下：

> Trace Trap[EXC_BREAKPOINT // SIGTRAP]
>  类似于异常退出，此异常旨在使附加的调试器有机会在其执行中的特定点中断进程。您可以使用该__builtin_trap()函数从您自己的代码触发此异常。如果没有附加调试器，则该过程将终止并生成崩溃报告。
>  较低级的库（例如，libdispatch）会在遇到致命错误时捕获进程。有关错误的其他信息可以在崩溃报告的“ 附加诊断信息”部分或设备的控制台中找到。
>
> 如果在运行时遇到意外情况，Swift代码将以此异常类型终止，例如：
>  1.具有nil值的非可选类型
>  2.一个失败的强制类型转换

对于swift还有一种崩溃需要捕获(Intel处理器,我认为应该是指在模拟器上的崩溃)，为保险起见，也需要将信号`SIGILL`进行注册，Apple同样对其中做了描述

> Illegal Instruction[EXC_BAD_INSTRUCTION // SIGILL]
>  该过程尝试执行非法或未定义的指令。该过程可能尝试通过错误配置的函数指针跳转到无效地址。
>  在Intel处理器上，ud2操作码引起EXC_BAD_INSTRUCTION异常，但通常用于进程调试目的。如果在运行时遇到意外情况，Intel处理器上的Swift代码将以此异常类型终止。有关详细信息，请参阅Trace Trap。

<br />

### 4 解除监听

监控Crash的代码都要执行解除监听

```
NSSetUncaughtExceptionHandler(NULL);
signal(SIGHUP, SIG_DFL);
```

这是因为：

1. 保证一个Crash只会被一个Hander处理，避免多次处理
2. 防止出现死锁导致应用不能退出

