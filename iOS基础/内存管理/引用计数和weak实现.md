## 引用计数和weak实现

通过上篇的内存管理，知道了iOS的内存管理使用的是引用计数的模式，通过记录对象的引用计数管理堆上的内存，新增引用时引用计数加1，释放对象引用计数减1，然后引用计数为0时执行销毁等操作。

通过weak可以解决循环引用的问题，也就是指向对象但不增加其引用计数。最后对象销毁的时候将weak修饰的指针指向nil。

接下来说明引用计数和weak的实现。

### 1 数据结构分析

对于引用计数和weak，需要通过以下数据结构来进行一步一步分析。

#### 1.1 SideTables

首先苹果创建了一个全局的SideTables，用来管理所有对象的引用计数，是一个全局的Hash表，从名称的结尾带s上看更像是个数组，也有部分文章称其为Hash数组，可以通过对象经过算法映射到对应的元素中。

SideTables的元素数量，通过源码得出是8或者64个。如下代码：

```
// SideTables 实质类型为模版类型StripedMap
static StripedMap<SideTable>& SideTables() {
    return *reinterpret_cast<StripedMap<SideTable>*>(SideTableBuf);
}

// 然后在StripedMap的定义中可以知道最后都映射成8个或者64个
// StripedMap<T> is a map of void* -> T, sized appropriately 
// for cache-friendly lock striping. 
// For example, this may be used as StripedMap<spinlock_t>
// or as StripedMap<SomeStruct> where SomeStruct stores a spin lock.
template<typename T>
class StripedMap {
#if TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR
    enum { StripeCount = 8 }; // 我看的这版手机端是8
#else
    enum { StripeCount = 64 };
#endif

    struct PaddedT {
        T value alignas(CacheLineSize); // T value 64字节对齐
        
    };

    PaddedT array[StripeCount]; // 所有PaddedT struct 类型数据被存储在array数组中。iOS 设备 StripeCount == 8

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

其中StripeCount是8，所以必定是在8个元素中找到对应的SideTable。

因为只有8个，所以必定存在Hash冲突，但苹果就是特意将不同的对象映射到同样的SideTable中，采用了分离锁技术，分别在元素处理时只锁定当前元素而不影响其他7个元素的处理。至于怎么找到对应的引用计数和Weak表，接下来一步一步分析。



#### 1.2 SideTable

使用SideTables[key]来得到SideTable后，SideTable的结构如下：

##### 1.2.1 一把自旋锁 spinlock_t slock;

作用是对当前SideTable加锁，避免数据读写错误。

至于为什么采用自旋锁。因为自旋锁比较适用于锁使用者保持锁时间比较短的情况，不需要睡眠，因为操作SideTable很频繁，所以采用了较快的方式加锁。

但其实spinlock_t在iOS10之后，因为优先级反转的问题，在源码的objc-os.h中spinlock_t对应的实际类型是mutex_tt，而mutex_tt的内部采用的是os_unfair_lock，不会忙等，会让线程休眠。



##### 1.2.2 引用计数器 RefcountMap refcnts;

对象的具体的引用计数就是在这里面。

RefcountMap是个Map。上述中说到，SideTables发生了Hash冲突后，多个对象都是映射到同一个SideTable中。而接下来找到对应的引用计数器，就是再一次通过内存地址进行映射查找，通过table.refcnts.find(this)找到对应的value。

找到对应引用计数器的数据类型是：

```
typedef __darwin_size_t        size_t;
```

定义的其实是unsigned long，

对于这个类型，从低位到高位：

**(1UL<<0)    WEAKLY_REFERENCED**

表示是否有弱引用指向这个对象，如果有的话，值为1，在对象释放的时候需要把所有weak的指向都变成nil，避免野指针。

**(1UL<<1)    DEALLOCATING**

表示是否正在被释放。1正在释放，0没有。

**REAL COUNT**

真正的引用计数存储区。加一或减一引用计数，实际上是加四或减四，因为是从2^2位开始的。

**(1UL<<(WORD_BITS-1))    SIDE_TABLE_RC_PINNED**

WORD_BITS-1在32位和64位对应32和64。随着引用计数不断变大，如果这一位变成了1，就表示引用计数已经最大了不能再加了。



##### 1.2.3 维护weak指针的结构体 weak_table_t weak_table;

上述RefcountMap是一个一层结构，可以用过对象key find查找到对应的value。weak_table_t是两层结构。

第一层包含两个元素：

**weak_entry_t *weak_entries;** 

是一个数组。因为是数组，我觉得是通过循环去找到对应的内存匹配的元素，但部分文章说这里也是通过映射Hash可以匹配到，源码中也调用了hash_pointer拿到index后再去entries里面匹配。

至于为什么引用计数用的是Map，为什么此处用的是数组。通过文章和我猜测，应该是觉得weak表不太频繁使用，所以使用了数组来处理。

**num_entries**

此元素是用来维护数组保证使用有一个合适的size，比较数组中元素的数超过3/4的时候将数组的大小乘以2。



第二层weak_entry_t的结构包含3个部分

**referent**

被指对象的地址，上诉中数组通过判断是否相等匹配到对应的元素。

**referrers**

可变数组，里面保持着所有指向这个对象的弱引用的地址。当这个对象被释放的时候，referrers里的所有指针都会被设置成nil。

**inline_referrers**

固定只有4个元素的数组，默认情况下没超过4个弱引用时使用的是该部分来存储。



### 2 根据伪代码过一遍流程

#### 2.1 alloc

调用alloc时并没有操作SideTable，但什么时候加入到对应的SideTable，我并没有找到。

我猜测是这样的过程：在后续的isa的结构已经不是单纯的指向类Class，而是实质结构体内包含了引用计数的位置，在大于10个引用计数时，就会加入到SideTable中。而isa没改之前，可能是在创建时就加入到SideTable中。

#### 2.2 retain

```
//1、通过对象内存地址，在SideTables找到对应的SideTable
SideTable& table = SideTables()[this];

//2、通过对象内存地址，在refcnts中取出引用计数
//这里是table是SideTable。refcnts是RefcountMap
size_t& refcntStorage = table.refcnts[this];

//3、判断PINNED位，不为1则+4
if (! (refcntStorage & PINNED)) {
    refcntStorage += (1UL<<2);
}
```

#### 2.3 release

```
table.lock();
引用计数器 = table.refcnts.find(this);
//table.refcnts.end()表示使用一个iterator迭代器到达了end()状态
if (引用计数器 == table.refcnts.end()) {
    //标记对象为正在释放
    table.refcnts[this] = SIDE_TABLE_DEALLOCATING;
} else if (引用计数器 < SIDE_TABLE_DEALLOCATING) {
    //这里很有意思，当出现小余(1UL<<1) 的情况的时候
    //就是前面引用计数位都是0,后面弱引用标记位WEAKLY_REFERENCED可能有弱引用1
    //或者没弱引用0

    //为了不去影响WEAKLY_REFERENCED的状态
    引用计数器 |= SIDE_TABLE_DEALLOCATING;
} else if ( SIDE_TABLE_RC_PINNED位为0) {
    引用计数器 -= SIDE_TABLE_RC_ONE;
}
table.unlock();
如果做完上述操作后如果需要释放对象，则调用dealloc
```

#### 2.4 dealloc

dealloc操作做了大量的逻辑判断和处理。

下面是objc_object::sidetable_clearDeallocating()

```
SideTable& table = SideTables()[this];
table.lock();
引用计数器 = table.refcnts.find(this);
if (引用计数器 != table.refcnts.end()) {
    if (引用计数器中SIDE_TABLE_WEAKLY_REFERENCED标志位为1) {
        weak_clear_no_lock(&table.weak_table, (id)this);
    }
    //从refcnts中删除引用计数器
    table.refcnts.erase(it);
}
table.unlock();
```

其中weak_clear_no_lock，是对象被销毁时处理弱引用指针的方法。

```
void 
weak_clear_no_lock(weak_table_t *weak_table, id referent_id) 
{
    //1、拿到被销毁对象的指针
    objc_object *referent = (objc_object *)referent_id;

    //2、通过 指针 在weak_table中查找出对应的entry
    weak_entry_t *entry = weak_entry_for_referent(weak_table, referent);
    if (entry == nil) {
        /// XXX shouldn't happen, but does with mismatched CF/objc
        //printf("XXX no entry for clear deallocating %p\n", referent);
        return;
    }

    //3、将所有的引用设置成nil
    weak_referrer_t *referrers;
    size_t count;
    
    if (entry->out_of_line()) {
        //3.1、如果弱引用超过4个则将referrers数组内的弱引用都置成nil。
        referrers = entry->referrers;
        count = TABLE_SIZE(entry);
    } 
    else {
        //3.2、不超过4个则将inline_referrers数组内的弱引用都置成nil
        referrers = entry->inline_referrers;
        count = WEAK_INLINE_COUNT;
    }
    
    //循环设置所有的引用为nil
    for (size_t i = 0; i < count; ++i) {
        objc_object **referrer = referrers[I];
        if (referrer) {
            if (*referrer == referent) {
                *referrer = nil;
            }
            else if (*referrer) {
                _objc_inform("__weak variable at %p holds %p instead of %p. "
                             "This is probably incorrect use of "
                             "objc_storeWeak() and objc_loadWeak(). "
                             "Break on objc_weak_error to debug.\n", 
                             referrer, (void*)*referrer, (void*)referent);
                objc_weak_error();
            }
        }
    }
    
    //4、从weak_table中移除entry
    weak_entry_remove(weak_table, entry);
}
```

