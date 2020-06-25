## Autoreleasepool实现

通过前部分的了解，内存管理中，对象延迟释放，可以对对象执行autorelease操作，其实也就是将其加入到autoreleasepool中，直到超出Autorelease的作用范围或者runloop的一次迭代结束时进行释放。在ARC中，编译器已自动添加了autorelease的代码，大部分情况下是不需要手动去autoreleasepool的操作，比如在较大循环内部有autorelease的对象时，可以使用@autoreleasepool{}来规定对象在指定作用域后释放，以此优化内存。

### 1 Autoreleasepool实现原理

#### 1.1 Autoreleasepool结构

在ARC下，使用@autoreleasepool{}来使用AutoreleasePool的功能特性时，编译器将其变成如下代码：

```
...
void *context = objc_autoreleasePoolPush();
// {}中的代码
objc_autoreleasePoolPop(context);
...
```

这两个函数都是AutoreleasePoolPage的封装，所以关键就是这个类。

**AutoreleasePoolPage**

Autoreleasepool是没有单独的内存结构的，是通过Autoreleasepool为节点的双向链表来实现的（parent指针和child指针）。

- 每一个线程的autoreleasepool其实就是一个指针的堆栈，与线程是一一对应的。
- 每一个指针代表一个需要release的对象或者POOL_SENTINEL(哨兵对象，代表一个autoreleasepool的边界)
- AutoreleasePoolPage每个对象会开辟4096字节内存，也就是虚拟内存一页的大小，除了变量所占用的空间，其余的空间都会用来储存执行了autorelease的对象的地址。
- 一个pool token就是这个pool所对应的POOL_SENTINEL的内存地址，当这个pool被pop的时候，所有内存地址在pool token之后的对象都要会执行release。
- 这个堆栈被划分成了一个以page为节点的双向链表。pages会在必要的时候新增或者减少。
- TLS(Thread-local storage)线程局部存储，指向hot page，也就是最新添加autorelease对象所在的page。



一个空的AutoreleasePoolPage的内存结构如下：

1. magic 用来校验 AutoreleasePoolPage的结构是否完整。
2. next 指向最新添加的autorelease对象的下一个位置，初始位置指向begin()。
3. thread 指向当前线程。
4. parent 指向父节点，第一个节点没有父节点，为nil。
5. child 指向子节点，最后一个节点没有子节点，为nil。
6. depth 代表深度，从0开始，然后往后递增。
7. hiwat 代表high water mark

当next == begin()时，表示该Page为空，当next == end()时，表示该Page满了。



**Autorelease Pool Blocks**

再次分析，@autoreleasepool的代码，C++代码如下

```
extern "C" __declspec(dllimport) void * objc_autoreleasePoolPush(void);
extern "C" __declspec(dllimport) void objc_autoreleasePoolPop(void *);
struct __AtAutoreleasePool {
  __AtAutoreleasePool() {atautoreleasepoolobj = objc_autoreleasePoolPush();}
  ~__AtAutoreleasePool() {objc_autoreleasePoolPop(atautoreleasepoolobj);}
  void * atautoreleasepoolobj;
};
/* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool;
}
```

通过声明了__AtAutoreleasePool类型的局部变量 _autoreleasepool来实现@autoreleasepool{}，当声明时，构造函数 AtAutoreleasePool()被调用，执行了

atautoreleasepoolobj = objc_autoreleasePoolPush();

当出了当前作用域时，~__AtAutoreleasePool()会被调用，执行

objc_autoreleasePoolPop(atautoreleasepoolobj);

因此，总结起来单个autoreleasepool的运行过程简单地理解为，objc_autoreleasePoolPush();，对象的autorelease 和 objc_autoreleasePoolPop(void *); 三个过程。



**push() 操作**

上述的 objc_autoreleasePoolPush(); 实际上执行的是 AutoreleasePoolPage::push();

一个push操作其实就是创建一个新的autoreleasepool，对应的Page的具体实现就是往Page中的next位置插入了一个POOL_SENTINEL，并且返回插入的POOL_SENTINEL的内存地址。这个地址也就是我们前面提到的pool token，在执行pop操作的时候的入参。

```
static inline void *push()
{
    id *dest = autoreleaseFast(POOL_SENTINEL);
    assert(*dest == POOL_SENTINEL);
    return dest;
}
```

然后autoreleaseFast函数负责执行插入操作。

```
static inline id *autoreleaseFast(id obj)
{
    AutoreleasePoolPage *page = hotPage();
    if (page && !page->full()) {
        return page->add(obj);
    } else if (page) {
        return autoreleaseFullPage(obj, page);
    } else {
        return autoreleaseNoPage(obj);
    }
}
```

此处有三种不同的处理：

1. 当前Page存在且没有满时，直接将对象添加到当前page中，即next指向的位置。
2. 当前Page存在且满了时，创建一个新的Page，并将对象添加到新的Page中；
3. 当前Page不存在时，即还没有page时，创建第一个Page，并将对象添加到新创建的Page中。

每调用一次push操作就会创建一个新的autoreleasepool，即往AutoreleasePoolPage中插入一个POOL_SENTINEL，并且返回插入的POOL_SENTINEL的内存地址。



**autorelease 操作**

通过源码分析，autorelease最终调用的就是AutoreleasePoolPage的autorelease函数。

而autorelease函数内部和push非常相似，只不过push操作时插入一个POOL_SENTINEL，而autorelease操作插入的是一个具体的autorelease对象。

```
static inline id autorelease(id obj)
{
    assert(obj);
    assert(!obj->isTaggedPointer());
    id *dest __unused = autoreleaseFast(obj);
    assert(!dest  ||  *dest == obj);
    return obj;
}
```



**pop(void *) 操作**

pop函数的入参就是push函数的返回值，也就是POOL_SENTINEL的内存地址，即pool token。当执行pop操作时，内存地址在pool token之后的所有autorelease对象都会执行一遍release。直到pool token所在page的next指向pool token为止。



#### 1.2 NSThead、NSRunLoop和NSAutoreleasePool

根据官方的NSRunLoop的描述，每一个线程，包括主线程，都会拥有一个专属的NSRunLoop对象，会在需要的时候自动创建。

同样在NSautoreleasePool的描述中，我们知道，在主线程的NSRunLoop对象的每个event loop开始前，系统会自动创建一个autoreleasepool，并在event loop结束时drain。这也就是最开始时说的runloop迭代后会执行对象的release操作。

另外，NSAutoreleasePool中还提到，每一个线程都会维护自己的autoreleasepool的堆栈，这也说明autoreleasepool是与线程密切相关的，从page中的属性也可以看出来，thread也就是对应的当前线程。



#### 1.3 Autorelease返回值的快速释放机制

在内存管理时，有提到，runtime会对autorlease返回值有优化，不会从autoreleasepool中取对象，而是检测到objc_autoreleaseReturnValue和objc_retainAutoreleasedReturnValue配套时，会直接返回对象。

```
+ (instancetype)createSark {
    id tmp = [self new];
    return objc_autoreleaseReturnValue(tmp); // 代替我们调用autorelease
}
// caller
id tmp = objc_retainAutoreleasedReturnValue([Sark createSark]) // 代替我们调用retain
Sark *sark = tmp;
objc_storeStrong(&sark, nil); // 相当于代替我们调用了release
```

其中用到的技术是 Thread Local Storage

Thread Local Storage，TLS，线程局部存储。目的很简单，就是将一块内存作为某个线程专有的存储，以key-value的形式进行读写。

```
void* pthread_getspecific(pthread_key_t);
int pthread_setspecific(pthread_key_t , const void *);
```

在返回值调用objc_autoreleaseReturnValue方法时，runtime将这个返回值object存储在TLS中，然后直接返回这个object，不调用autorelease。同时，在外部接手这个返回值的objc_retainAutoreleasedReturnValue里，发现TLS中正好存了这个对象，那么直接返回这个object，不调用retain。



#### 1.4 总结

通常的ARC情况下，我们是不需要手动添加autoreleasepool的，使用的是线程自动维护的autoreleasepool就好，在以下三种情况需要添加autoreleasepool：

1. 如果你编写的程序不是UI框架的，而是命令行工具。
2. 如果你编写的循环中创建了大量的临时对象。
3. 如果你创建了一个辅助线程。