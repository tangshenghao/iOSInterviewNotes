## runtime和消息机制

### 1 runtime

源代码转换为可执行程序，需要经过三个步骤：编译、链接、运行。

在C语言中，到链接的时候，对象的类型、方法的实现就已经确定了。

而在OC中，编译和链接过程中的工作，放到了运行阶段。也就是在没运行的时候，并不知道调用一个方法会发生什么。因此称OC为动态语言。

实现动态特性的基础就是runtime。runtime是底层纯C语言的API库，OC代码会被编译器转换成运行时代码，通过消息机制决定函数调用方式。

runtime可以在运行时创建对象、检查对象，修改类和对象的方法。其中核心内容是消息传递。



### 2 runtime消息传递

#### 2.1 消息传递流程

一个对象的调用方法，例如[obj foo]。

在编译器阶段，编译器转换后会变成objc_msgSend(obj, foo)。然后到运行时，runtime执行的流程如下：

1. 先通过实例obj的isa指针，找到obj的class类对象；
2. 在class类对象中的objc_cache中查找是否有缓存的方法
3. 如果没有缓存的方法，则去查找objc_method_list中的方法
4. 如果没有找到对应的方法，则会继续往它的父类superclass中查找
5. 如果找到了方法，将method_name作为key，method_imp作为value存到缓存中，以便下次不用再次到方法列表中查找
6. 有对应的IMP后，可以通过找到方法实现的函数。
7. 如果没有找到则执行消息转发过程
8. 如果消息转发也失败了，就会报出找不到方法的崩溃



根据上篇类和对象中，知道的isa指针的对应指向。

**实例对象**

其中，对象的源码中

```
/// Represents an instance of a class.
struct objc_object {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
};

/// A pointer to an instance of a class.
typedef struct objc_object *id;
```

对象的结构体只包含一个指向类的isa指针。

也就是调用方法时，通过isa指针，找到Class类。



**类**

然后接着看Class，class的定义是objc_class结构体

```
struct objc_class {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;

#if !__OBJC2__
    Class _Nullable super_class                              OBJC2_UNAVAILABLE;
    const char * _Nonnull name                               OBJC2_UNAVAILABLE;
    long version                                             OBJC2_UNAVAILABLE;
    long info                                                OBJC2_UNAVAILABLE;
    long instance_size                                       OBJC2_UNAVAILABLE;
    struct objc_ivar_list * _Nullable ivars                  OBJC2_UNAVAILABLE;
    struct objc_method_list * _Nullable * _Nullable methodLists                    OBJC2_UNAVAILABLE;
    struct objc_cache * _Nonnull cache                       OBJC2_UNAVAILABLE;
    struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
#endif

} OBJC2_UNAVAILABLE;
```

通过对象的isa指针，找到了对应的类的结构体。

方法调用时，通过结构体中的objc_method_list和objc_cache进行方法的查找。该类结构体中的方法为实例方法。



**元类**

而在类中，也有一个isa指向Class，此处指向元类，也就时类对象所属的类，其中结构体中的信息和类的信息类似，方法列表中存储的是类方法。

比如，调用类方法时，流程是通过类的isa指针，找到元类，然后再通过元类的objc_method_list和objc_cache进行方法的查找。



**Method**

在上述描述中，在objc_method_list中存储了定义的方法，方法的结构体如下：

```
/// An opaque type that represents a method in a class definition.
/// 代表类定义中一个方法的不透明类型
typedef struct objc_method *Method;

struct objc_method {
    SEL _Nonnull method_name;                    // 方法名
    char * _Nullable method_types;               // 方法类型
    IMP _Nonnull method_imp;                     // 方法实现
};
```

包含了，方法名、方法类型、方法实现。

- SEL方法名

SEL方法名是指向obj_selector的指针，在源码中未能找到其结构体定义，不过通过代码可以看出，实际上SEL存的就是方法的字符串。

在OC中，同一个类是不可以方法名重复，即使传入的参数格式不一样也不行，实现不了函数重载的处理。因为SEL只存储了方法名，并不记录-/+或者参数类型等信息。

- IMP方法实现

IMP实际上是一个指针，指向方法的实现函数。通过IMP找到函数地址，然后执行函数。

- method_types 方法类型

方法类型是字符串，用来存储方法中的参数类型和返回值的类型。



#### 2.2 消息转发流程

在上述消息发送的过程中，先是在对应的类中查找方法，接着往上一层层找父类的方法。当在最后一层的父类也没找到方法时。runtime会执行消息转发的机制。

消息转发机制如下图所示：

![[https://github.com/tangshenghao/iOSInterviewNotes/blob/master/iOS%E5%9F%BA%E7%A1%80/runtime%E5%92%8C%E6%B6%88%E6%81%AF%E6%9C%BA%E5%88%B6/%E6%B6%88%E6%81%AF%E8%BD%AC%E5%8F%91.jpeg](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/iOS基础/runtime和消息机制/消息转发.jpeg)]()

从图中来看，主要分为3大步骤：

1. Method resolution 方法解析阶段
2. fast forwarding 快速转发阶段
3. Normal forwarding 常规转发阶段

当类和父类都找不到对应SEL时，为了不发生unrecognized selector 的错误，需要使用上述三种方式进行消息发送的补救。



**Method resolution 方法解析阶段**

在进入消息转发阶段后，第一步是先调用+ (BOOL)resolveInstanceMethod:(SEL)sel或+ (BOOL)resolveClassMethod:(SEL)sel来询问是否实现了对应的处理，如果返回YES，则能接受对应的消息并进行处理，返回NO则不会进行处理，进入下一步。

在NSObject源码中，这两个类方法返回的NO。需要对其进行处理，需要进行重写方法和实现。

其中调用的实例方法对应的是resolveInstanceMethod。

代码如下：

```
TestObject *test = [[TestObject alloc] init];
//比如 调用了一个没有定义的方法
[test performSelector:@selector(logTest)];
```

在TestObject中的resolution的补救代码如下：

```
void dynamicMethodIMP(id self, SEL _cmd) {
    NSLog(@" dynamicMethodIMP ");
}

@implementation TestObject

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    
    if ([NSStringFromSelector(sel) isEqualToString:@"logTest"]) {
        NSLog(@"添加resolveInstanceMethod转发方法");
        
        //实例方法需要添加到类中
        class_addMethod([self class], sel, (IMP)dynamicMethodIMP, "v@:");
        
        return YES;
    }
    
    return [super resolveInstanceMethod:sel];
}

```

类方法对应的是resolveClassMethod。

代码如下：

```
[TestObject performSelector:@selector(logTest)];
```

在TestObject中的resolution的补救代码如下：

```
+ (BOOL)resolveClassMethod:(SEL)sel {
    if ([NSStringFromSelector(sel) isEqualToString:@"logTest"]) {
        NSLog(@"添加resolveClassMethod转发方法");
        
        //类方法需要插入到元类中
        Class metaClass = objc_getMetaClass([NSStringFromClass([self class]) UTF8String]);
        
        class_addMethod(metaClass, sel, (IMP)dynamicMethodIMP, "v@:");
        
        return YES;
    }
    
    return [super resolveInstanceMethod:sel];
}
```



**Fast forwarding快速转发阶段** 

在消息转发的第一步Method resolution没有得到添加方法的YES返回。那么将进入第二步，需要问一下有没有别人帮忙处理这个方法。

调用的是- (id)forwardingTargetForSelector:(SEL)aSelector。

在NSObject的源码中快速转发的方法返回的都是nil。

创建一个别的类来实现响应对应的方法。

然后实现对应的方法复写，代码如下：

```
// 消息转发第二步 Fast forwarding 快速转发阶段
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([NSStringFromSelector(aSelector) isEqualToString:@"logTest"]) {
        Class TestObjectTwo = NSClassFromString(@"TestObjectTwo");
        //返回实例对象
        return [[TestObjectTwo alloc] init];
    }
    
    return [super forwardingTargetForSelector:aSelector];
}
```

如果是类方法，代码如下：

```
+ (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([NSStringFromSelector(aSelector) isEqualToString:@"logTest"]) {
        Class TestObjectTwo = NSClassFromString(@"TestObjectTwo");
        //返回类对象
        return TestObjectTwo;
    }
    
    return [super forwardingTargetForSelector:aSelector];
}
```

使用这个特性，可以做一些解耦或者循环引用的问题，例如，NSTimer导致循环引用的问题。



**Normal Forwarding 常规转发阶段**

如果第二步返回self或者nil，则找不到可以响应的对象去执行。接下来进入第三步。

第三步的消息转发机制，本质上跟第二步是一样的，都是切换接受消息的对象。但第三步切换响应目标更复杂一些，第二步只需要返回可以响应的对象即可，第三步还需要手动将响应方法切换给备用响应对象。

第三步有2个步骤

- methodSignatureForSelector
- forwardInvocation

methodSignatureForSelector中，返回SEL方法的签名，返回的签名是根据方法的参数来封装的。

手动创建签名，但是尽量少使用，因为容易创建错误。

代码如下，先实现methodSignatureForSelector

```
// 3.1 先创建签名标签
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    //写法例子
    //例子"v@:@"
    //v@:@ v 返回值类型void;@ id类型,执行sel的对象;: SEL;@ 参数
    //例子"@@:"
    //@ 返回值类型id;@ id类型,执行sel的对象;: SEL
    
    if ([super methodSignatureForSelector:aSelector] == nil) {
        NSMethodSignature *sign = [NSMethodSignature signatureWithObjCTypes:"v@:"];
        return sign;
    }
    
    return [super methodSignatureForSelector:aSelector];
}
```

然后再实现forwardInvocation

```
// 执行消息转发调用
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    //创建备用对象
    Class TestObjectTwo = NSClassFromString(@"TestObjectTwo");
    id testObjectTwo = [[TestObjectTwo alloc] init];
    SEL sel = anInvocation.selector;
    
    if ([TestObjectTwo respondsToSelector:sel]) {
        [anInvocation invokeWithTarget:testObjectTwo];
    } else {
        [self doesNotRecognizeSelector:sel];
    }
}
```

类方法转发，只需要将-变成+，然后forwardInvocation中的target使用Class。

以上就是消息转发机制，转发过程越早越好，第一步实现添加后，runtime会缓存到方法缓存里面，下次再调用可以提高效率。后续得每次都得进行代码查找调用。最后一步需要处理完整的NSInvocation。

消息转发可以动态添加部分方法。可以实现多重代理，不不同的对象同时代理同个毁掉，然后再各自负责的区域进行相应的处理，降低代码耦合。以及简洁实现多即成。



### 3 runtime应用场景

#### 3.1 Method Swizzling方法交换

使用方法交换，对业务逻辑进行分离，降低耦合度。

比如，在所有页面都添加统计功能，其中除了手动添加和继承一个基类或使用分类来解决之外，就是使用Method Swizzling来解决。或者是对一些不能改动源码的方法做hook处理。

交换的实际上是Selector和IMP的对应关系。从而达到通过selector去查找调用时，实际上执行的是交换后的IMP。

一般交换是在+load中完成，应该只在dispatch_once中交换。+load是在类加载的时候就被调用，启动时就会先加载所有的类，在main函数之前就会执行+load方法。

+initialize类似懒加载，是在类或者子类的第一个方法被调用时调用，默认只加载一次。+initialize调用发生在+init之前。

|                                  | +load                      | +initialize                  |
| -------------------------------- | -------------------------- | ---------------------------- |
| 执行时机                         | 在mian函数之前             | 在类的方法被第一次调用时执行 |
| 若自身未定义，是否沿用父类的方法 | 否                         | 是                           |
| 类别中的定义                     | 全都执行，但在类中的方法后 | 覆盖类中的方法，只执行一次   |



交换的代码如下：

```

```

