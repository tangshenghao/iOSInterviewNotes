## block

### 1 block概念

block实际上是Objective-C对于闭包的实现。带有自动变量（局部变量）的匿名函数。

#### 1.1 block本质

block本质上是一个OC对象，它内部也有isa指针。

block是封装了函数调用以及函数调用环境的OC对象



#### 1.2 block数据结构分析

block的结构如下图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/iOS%E5%9F%BA%E7%A1%80/block/block%E5%BA%95%E5%B1%82%E7%BB%93%E6%9E%84.jpg?raw=true)

通过生成cpp文件查看转换后的代码来了解

```
int i = 2;
void (^Test10block)(void) = ^{
    NSLog(@"123123:%d",i);
};
Test10block();
```

使用xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m转换后为

```
int i = 2;
void (*Test10block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, i));
((void (*)(__block_impl *))((__block_impl *)Test10block)->FuncPtr)((__block_impl *)Test10block);
```

其中block的本质就是一个结构体对象，结构体__main_block_impl_0的代码如下：

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int i;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _i, int flags=0) : i(_i) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

其中结构体内含有一个i。是捕获的局部变量。

结构体中struct __block_impl impl;的代码如下：

```
struct __block_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
};
```

struct __main_block_desc_0* Desc;代码如下：

```
static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
```

调用方法中的__main_block_func_0，是封装了block内执行的逻辑函数

```
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int i = __cself->i; // bound by copy

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_hz_6yv0h07n6mz76tv81_0rmgmr0000gn_T_main_d47b21_mi_0,i);
        }
```



#### 1.3 block变量捕获

以下三种情况变量捕获情况

| 变量类型       | 捕获到block内部 | 访问方式 |
| -------------- | --------------- | -------- |
| 局部变量auto   | 是              | 值传递   |
| 局部变量static | 是              | 指针传递 |
| 全局变量       | 否              | 直接访问 |



##### 1.3.1 局部变量auto-自动变量

就是如上节所示，局部变量i，就是被捕获近block内部。

其中

```
void (*Test10block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, i));
```

最后有一个参数i直接传递进去，直接给到了结构体__main_block_impl_0，所以在block外修改i是不会对内部造成影响的。



##### 1.3.2 局部变量 static

因为定义为static后，变量不会被销毁，所以传递的是指针类型。block外部改变，也会引起内部的改变。

例如：

```
static int i = 2;
void (^Test10block)(void) = ^{
    NSLog(@"123123:%d",i);
};
Test10block();
```

执行编译器转换代码后可以得到：

```
void (*Test10block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, &i));

//其中 i 是指针类型
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int *i;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int *_i, int flags=0) : i(_i) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

传递的时候用到的是&i，然后结构体内使用的是*i，所以block外改动可以获取到。



##### 1.3.3 全局变量

定义成全局变量，变量也是不会被销毁，并且不用进行传递。block内部直接调用的全局变量。

编译器转换后的代码如下：

```
void (*Test10block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));
```

没有进行传值。



##### 1.4 Block类型

block有三种类型，可以通过调用class方法或者isa指针查看具体的类型，最终都是继承自NSBlock类，NSBlock类继承自NSObject类。

```
//执行打印 查看类型
NSLog(@"class = %@, super Class = %@, base Class = %@", [Test7Block class], [[[Test7Block class] superclass] superclass], [[[[Test7Block class] superclass] superclass] superclass]);

//输出为
2020-07-03 17:35:54.547663+0800 test15[29530:5289436] class = __NSMallocBlock__, super Class = NSBlock, base Class = NSObject
```

三种类型和对应的环境如下

| 类型          | 内存位置      | 环境                   |
| ------------- | ------------- | ---------------------- |
| NSGlobalBlock | 全局/数据区域 | 没有访问auto变量       |
| NSStackBlock  | 栈区          | 访问了auto变量         |
| NSMallocBlock | 堆区          | NSStackBlock调用了copy |



##### 1.5 MRC和ARC下的区别

MRC下如果访问了auto变量，但是不执行copy的话，block会一直在栈区。ARC下编译器会根据特定情况自动做copy处理。

以下几种情况会编译器会调用copy

- block作为函数的返回值时
- 将block赋值给__strong指针时
- block作为Cocoa API中方法名含有usingBlock的方法参数时
- block作为GCD API的方法参数时

其中在ARC下block的属性修饰词，可以使用copy或者strong，因为对应的所有权修饰都是__strong，编译器都会进行一次copy到堆上的操作。但是MRC下需要使用copy进行修饰。

上述usingBlock的方法，例如数组的block遍历：

```
NSArray *array = @[@1,@4,@5];
[array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // code
}];
```

当block为栈block类型时，无论外面使用的是strong或者是weak都不会对外面的对象进行强引用。

当block为堆block类型时，block内部的_Block_object_assign函数会根据strong或者weak对外界的对象进行强引用或弱引用。

block内部访问了对象类型的auto变量时，如果block是在栈上，将不会对auto变量产生强引用。

**如果block被拷贝到堆上，有以下操作**：

1. 会调用block内部的copy函数
2. copy函数内部会调用_Block_object_assign函数
3. 该函数会根据变量的修饰词作出对应的操作，强引用或者弱引用

**如果block从堆上移除，有以下操作：**

1. 会调用block内部的dispose函数
2. dispose函数内部会调用_Block_object_dispose函数
3. 该函数会自动释放引用的变量



#### 1.6 __Block修饰

直接在block内部修改auto变量，编译器会报错，如下：

```
Variable is not assignable (missing __block type specifier)
```

如果改成全局变量或者static变量，可以在block内部对变量进行修改。

但是这两种方式是会让变量一直在内存中。另外一种就是__block修饰。

通过代码来分析：

```
__block int i = 2;
void (^Test10block)(void) = ^{
    i = 3;
    NSLog(@"i的值为:%d",i);
};
```

转换后的代码：

```
//传入的是__Block_byref_i_0结构体
void (*Test10block)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, (__Block_byref_i_0 *)&i, 570425344));

//block的结构体中捕获的是__Block_byref_i_0结构体指针
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_i_0 *i; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_i_0 *_i, int flags=0) : i(_i->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

//__Block_byref_i_0结构体
struct __Block_byref_i_0 {
  void *__isa;
__Block_byref_i_0 *__forwarding;
 int __flags;
 int __size;
 int i;
};
```

__Block_byref_i_0的第二个参数的类型也是本身的结构体，forwarding里面存放的是指向自身的指针。

调用的时候，先用forwarding找到自己，然后取出对应的值

```
__Block_byref_i_0 *i = __cself->i; // bound by ref
(i->__forwarding->i) = 3;
```

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/iOS%E5%9F%BA%E7%A1%80/block/___block%E7%9A%84%E7%BB%93%E6%9E%84%E4%BD%93.jpg?raw=true)

__ block可以用于解决block内部无法修改auto变量值的问题，但不能修饰全局变量和静态变量。

原理是编译器会讲__block修饰的变量包装成一个结构体对象，然后通过结构体的指针找到变量所在的内存，然后进行值的修改



### 2 block内存管理

#### 2.1 block访问OC对象

当block内部访问外部的OC对象时，例如：

```
NSObject *test1 = [[NSObject alloc] init];
void (^Test10block)(void) = ^{

    NSLog(@"OC对象:%@",test1);
};
Test10block();
```

通过编译器转换后，代码如下：

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  NSObject *__strong test1;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, NSObject *__strong _test1, int flags=0) : test1(_test1) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  NSObject *__strong test1 = __cself->test1; // bound by copy


            NSLog((NSString *)&__NSConstantStringImpl__var_folders_hz_6yv0h07n6mz76tv81_0rmgmr0000gn_T_main_99ac31_mi_0,test1);
        }
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->test1, (void*)src->test1, 3/*BLOCK_FIELD_IS_OBJECT*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->test1, 3/*BLOCK_FIELD_IS_OBJECT*/);}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
```



通过上述的解释，因为在ARC下，会执行copy，从栈拷贝到堆上，结构体__main_block_desc_0中包含copy和dispose。

copy会调用__main_block_copy_0

```
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->test1, (void*)src->test1, 3/*BLOCK_FIELD_IS_OBJECT*/);}
```

其中_Block_object_assign会根据代码中的修饰符strong或者weak对其进行强引用或者弱引用。

查看__main_block_impl_0

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  // strong 强引用
  NSObject *__strong test1;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, NSObject *__strong _test1, int flags=0) : test1(_test1) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

可以看到修饰符是strong，所以调用_Block_object_assign时候，会对其进行强引用。

拷贝的时候，会调用block内部的copy函数，copy函数内部会调用_Block_object_assign函数，然后对__block变量形成强引用(retain)

再看一个例子：

```
int j = 6;
self.block5 = ^int(int t) {
    NSLog(@"%d---%d", t, j);
    return t;
};
```

因为j是在栈上的，在block内部引用j，但是当block从栈上拷贝到堆上时，怎么能保证下次block访问j时，能访问的到。

假设现在有两个栈上的block，分别是block0和block1，同时引用了栈上的__block变量，现在对block0进行copy操作，block会复制到堆上，因为block0持有 _block变量，所以也会把这个变量复制到堆上，同时堆上的block0对堆上的变量是强引用，所以这样能达到block0随时能访问到该变量。

此时如果block也拷贝到堆上，因为刚才block中的变量已经拷贝到堆上了，就不需要再次拷贝，只需要把堆上的block1也强引用堆上的变量就可以了。

然后释放的时候

会调用block内部的dispose函数

dispose函数内部会调用_block_object_dispose函数，该函数会自动释放引用的__block变量(release)

上述block0和block1都引用block变量，当block销毁时候，直接销毁堆上的block变量，但需要两个都废弃时，才会废弃__blcok变量。

其实就和引用计数一样，都没有引用时才废弃。

__block中的forwarding指针

```
struct __Block_byref_test1_0 {
  void *__isa;
__Block_byref_test1_0 *__forwarding;
 int __flags;
 int __size;
 void (*__Block_byref_id_object_copy)(void*, void*);
 void (*__Block_byref_id_object_dispose)(void*);
 NSObject *__strong test1;
};
```

访问的时候，使用test1->__forwarding->test1

```
NSLog((NSString *)&__NSConstantStringImpl__var_folders_hz_6yv0h07n6mz76tv81_0rmgmr0000gn_T_main_ec5054_mi_0,(test1->__forwarding->test1), (test2->__forwarding->test2), (test3->__forwarding->test3));
```

为什么不直接使用test1，而是需要通过__forwarding去调用呢？

因为，如果__变量还在栈上，是可以直接访问，但是如果已经拷贝到堆堆上，访问时，还去访问栈上的，就会出问题，所以先根据forwarding找到堆上的地址，然后再去取值，如下图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/iOS%E5%9F%BA%E7%A1%80/block/block%E5%8F%98%E9%87%8Fforwarding%E6%8C%87%E5%90%91.jpg?raw=true)

所以，上诉中说的，当block在栈上时，对变量都不会产生强引用，当拷贝到堆上时，通过copy函数对变量进行处理。





#### 2.2 block循环引用问题

上述中既然block有对其变量进行强引用，那么就有可能存在循环引用

如果一个对象有一个block的强引用的属性，然后这个block的实现代码中又调用了该对象，就会存在循环引用，释放不了该对象。

```
TestObject *test = [[TestObject alloc] init];
test.testBlock = ^{
    NSLog(@"调用了对象:%@",test);
};
```

可以用__weak来解决循环引用

```
__weak typeof(test) weakTest = test;
```

也可以用使用__unsafe_unretained来解决循环引用，但是一般不使用，因为对象相会时不会将指针执行nil，会造成野指针的情况。

使用__block也可以解决，但是需要在最后将对象置nil。也必须调用一遍该block。最好还是使用weak修饰的方式来解决，并且还需要在block内部使用strong再次进行修饰，不然会在部分延时或者异步的操作中找不到对应的值。

```
TestObject *test = [[TestObject alloc] init];
__weak typeof(test) weakTest = test;
test.testBlock = ^{
    __strong typeof(weakTest) strongTest = weakTest;
    NSLog(@"调用了对象:%@",weakTest);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"delay调用了对象:%@",strongTest);
    });
};
```

