## 引用计数和weak实现

通过上篇的内存管理，知道了iOS的内存管理使用的是引用计数的模式，通过记录对象的引用计数管理堆上的内存，新增引用时引用计数加1，释放对象引用计数减1，然后引用计数为0时执行销毁等操作。

通过weak可以解决循环引用的问题，也就是指向对象但不增加其引用计数。最后对象销毁的时候将weak修饰的指针指向nil。

接下来说明引用计数和weak的实现。

### 1 数据结构分析

对于引用计数和weak，需要通过以下数据结构来进行一步一步分析。

#### 1.1 SideTables

首先苹果创建了一个全局的SideTables，用来管理所有对象的引用计数。是一个全局的Hash表，从名称的结尾带s上看更像是个数组，也有部分文章称其为Hash数组，可以通过对象的Hash映射到对应的元素中。

SideTables的元素数量，通过源码得出是64个。如下代码：

```
// SideTables 实质类型为模版类型StripedMap
static StripedMap<SideTable>& SideTables() {
    return *reinterpret_cast<StripedMap<SideTable>*>(SideTableBuf);
}

// 然后在StripedMap的定义中可以知道最后都映射成64个
// StripedMap<T> is a map of void* -> T, sized appropriately 
// for cache-friendly lock striping. 
// For example, this may be used as StripedMap<spinlock_t>
// or as StripedMap<SomeStruct> where SomeStruct stores a spin lock.
template<typename T>
class StripedMap {

    enum { CacheLineSize = 64 };

#if TARGET_OS_EMBEDDED
    enum { StripeCount = 8 };
#else
    enum { StripeCount = 64 };  // iOS 设备的StripeCount = 64
#endif

    struct PaddedT {
        T value alignas(CacheLineSize); // T value 64字节对齐
        
    };

    PaddedT array[StripeCount]; // 所有PaddedT struct 类型数据被存储在array数组中。iOS 设备 StripeCount == 64

    static unsigned int indexForPointer(const void *p) { // 该方法以void *作为key 来获取void *对应在StripedMap 中的位置
        uintptr_t addr = reinterpret_cast<uintptr_t>(p);
        return ((addr >> 4) ^ (addr >> 9)) % StripeCount; // % StripeCount 防止index越界
    }

 ......
};

```

通过对象的地址映射到具体的元素，是使用

```
return ((addr >> 4) ^ (addr >> 9)) % StripeCount;
```

其中StripeCount是64，所以必定是在64个元素中找到对应的SideTable。

因为只有64个，所以必定存在Hash冲突，但苹果就是特意将不同的对象映射到同样的SideTable中，采用了分离锁技术，分别在元素处理时只锁定当前元素而不影响其他63个元素的处理。至于怎么找到对应的引用计数和Weak表，接下来一步一步分析。



#### 1.2 SideTable

使用SideTables[key]来得到SideTable后，SideTable的结构如下：

1.2.1 一把自旋锁 spinlock_t slock;

作用是对当前SideTable加锁，避免数据读写错误。

1.2.2 引用计数器 RefcountMap refcnts;

对象的具体的引用计数就是在这里面。

RefcountMap是个Map。上述中说到，SideTables发生了Hash冲突后，多个对象都是映射到同一个SideTable中。而接下来找到对应的引用计数器，就是再一次通过内存地址进行映射查找，通过table.refcnts.find(this)找到对应的value。

找到对应引用计数器的数据类型是：

```
typedef __darwin_size_t        size_t;
```

定义的其实是unsigned long，

对于这个类型，从地位到高位：

(1UL<<0)    WEAKLY_REFERENCED

表示是否有弱引用指向这个对象，如果有的话，值为1，在对象释放的时候需要把所有weak的指向都变成nil，避免野指针。

(1UL<<1)    DEALLOCATING

表示是否正在被释放。1正在释放，0没有。

REAL COUNT

真正的引用计数存储区，