## KVC和KVO

### 1 KVC

#### 1.1 KVC定义

KVC键值编码，是指在iOS的开发中，可以允许开发者通过Key名直接访问对象的属性，或者给对象的属性赋值，而不需要调用明确的存取方法。这样就可以在运行时动态地访问和修改对象的属性。而不是在编译时确定，这也是iOS开发中动态的特性之一。在实现了访问器方法的类中，使用点语法和KVC访问对象其实差别不大，二者可以任意混用。但是没有访问器方法的类中，点语法无法使用，这时就可以用KVC进行操作。

KVC的定义都是对NSObject的拓展来实现的，OC中有个显式的NSKeyValueCoding类别名，所以对于所有继承了NSObject的类型，都能使用KVC，一些纯Swift类和结构体是不支持KVC的，因为没有继承NSObject。以下是KVC中最重要的四个方法：

```
//通过Key取值
- (nullable id)valueForKey:(NSString *)key;

//通过KeyPath取值
- (nullable id)valueForKeyPath:(NSString *)keyPath;

//通过Key设置值
- (void)setValue:(nullable id)value forKey:(NSString *)key;

//通过Keypath设置值
- (void)setValue:(nullable id)value forKeyPath:(NSString *)keyPath;
```

在NSKeyValueCoding中还有一些其他方法，例如：

```
//默认返回YES，表示如果没有找到Set<Key>或_set<Key>方法的话，会按照_key，_iskey，key，iskey的顺序搜索成员，设置成NO就不这样搜索
+ (BOOL)accessInstanceVariablesDirectly;

//检查设置的key和值是否正确，不正确的值做替换或者返回错误原因
- (BOOL)validateValue:(inout id _Nullable * _Nonnull)ioValue forKey:(NSString *)inKey error:(out NSError **)outError;

//部分操作集合的方法
...
```



#### 1.2 KVC赋值和取值流程

##### 1.2.1 setValue:forkey赋值流程

主要为以下步骤：

1. 先按照setKey和_setKey的顺序到方法列表中寻找这两个方法，如果找到了方法则传参并且调用方法。

2. 如果没有找到上述方法，则通过accessInstanceVariablesDirectly方法的返回值来决定是否要查找成员变量。如果返回YES，则会按照以下顺序到成员变量中查找对应的成员变量：

   _key

   _isKey

   key

   isKey

3. 如果accessInstanceVariablesDirectly返回NO，则直接抛出NSUnknownKeyException异常。

4. 如果在成员变量列表中找到对应的属性值，则直接赋值，如果四种格式的成员变量都找不到，则抛出NSUnknownKeyException异常。



##### 1.2.2 valueForKey取值流程

主要为以下步骤：

1. 先按照getKey、key、isKey和_key的顺序到方法列表中寻找这四个方法，如果找到了方法则传参并且调用方法。

2. 如果没有找到上述方法，则通过accessInstanceVariablesDirectly方法的返回值来决定是否要查找成员变量。如果返回YES，则会按照以下顺序到成员变量中查找对应的成员变量：

   _key

   _isKey

   key

   isKey

3. 如果accessInstanceVariablesDirectly返回NO，则直接抛出NSUnknownKeyException异常。

4. 如果在成员变量列表中找到对应的属性值，则直接赋值，如果四种格式的成员变量都找不到，则抛出NSUnknownKeyException异常。



#### 1.3 KVC集合处理

简单集合运算符有@avg、@count、@max、@min、@sum5种，分别是平均值、数量、最大值、最小值、和值。例如代码如下：

```
TestObject *test3 = [[TestObject alloc] init];
test3.age = 13;
TestObject *test4 = [[TestObject alloc] init];
test4.age = 14;
TestObject *test5 = [[TestObject alloc] init];
test5.age = 15;
TestObject *test6 = [[TestObject alloc] init];
test6.age = 15;

NSArray *array = @[test3, test4, test5, test6];
NSNumber *number = [array valueForKeyPath:@"@min.age"];
NSLog(@"5-%f",number.floatValue);

//输出的是
5-13.000000
```



比集合运算发稍微复杂，能够以数组的方式返回指定内容，一共有两种：

- @distinctUnionOfObjects
- @unionOfObjects

前者是会根据条件过滤掉重复的元素，后者是返回全部的元素

```
NSArray *tempArray = [array valueForKeyPath:@"@distinctUnionOfObjects.age"];
NSLog(@"6-%@",tempArray);
```



对字典的处理，可以通过

- dictionaryWithValuesForKeys
- setValuesForKeysWithDictionary

来分别处理模型和字典的转换，代码如下：

```
 NSDictionary *tempDictionay = @{@"name":@"xxxx", @"age":@18};
 [test6 setValuesForKeysWithDictionary:tempDictionay];
 NSLog(@"7-%@, %d", test6.name, test6.age);
 
 NSDictionary *tempDictionary2 = [test6 dictionaryWithValuesForKeys:@[@"name", @"age"]];
 NSLog(@"8-%@",tempDictionay2);
```



#### 1.4 KVC使用场景

##### 1.4.1 动态获取值和赋值

最基本的用法

##### 1.4.2 访问和修改私有变量

对于类里的私有属性，OC是无法直接点语法访问的，但是KVC可以访问并且赋值。

##### 1.4.3 Model和字典转换

KVC和runtime组合实现Model和字典的转换

##### 1.4.4 修改系统控件的内部属性

例如UITextField中的placeHolderText

##### 1.4.5 操作集合

如上小节中所述，可以方便做一些处理。

##### 1.4.6 可以实现消息传递

对容器类使用KVC时，valueForKey:将会被传递给容器中的每一个对象，结果会返回一个处理后的容器。例如valueForKey:@"capitalizedString"来处理元素中首字符大写。



### 2 KVO

#### 2.1 KVO定义

KVO即键值观察，他是一种观察者模式的衍生。基本思想是对目标对象的某属性添加观察，当该属性发生变化时，通过触发观察者对象实现的KVO接口方法，来自动的通知观察者。

和KVC类似，KVO的定义也是对NSObject的拓展来实现的，OC中有个显式的NSKeyValueObserving类别名，所有继承了NSObject的类型，都能使用KVO。



#### 2.2 KVO的使用

使用KVO需要对要观察的属性的类添加观察。同时在不需要观察时移除观察，接口如下：

```
//添加观察
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;

//移除观察
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

```

其中参数说明如下：

```
observer：观察者，需要通知的订阅者。
keyPath：被观察者中要被观察的属性。
options：KVO的一些属性配置，有四个选项。
context：上下文，这个会传递到订阅者的函数中，用来做区分。
```

options中四种类型如下：

- NSKeyValueObservingOptionNew  - change字典包含改变后的值
- NSKeyValueObservingOptionOld - change字典包含改变前的值
- NSKeyValueObservingOptionInitial  - 注册后立刻出发KVO通知
- NSKeyValueObservingOptionPrior  - 值改变前是否也要通知，如果设置了该值，则会在属性改变前后都进行通知

监听回调函数为：

```
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context;
```

change内部监听的关键信息。

整体调用的代码例子如下：

```
TestObject *test7 = [[TestObject alloc] init];
    [test7 addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
test7.name = @"asdasd";


//回调函数
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"object = %@, keyPath = %@, change = %@",object, keyPath, change);
}

//输出如下
object = <TestObject: 0x600000da4000>, keyPath = name, change = {
    kind = 1;
    new = aaaa;
    old = "<null>";
}
```



手动KVO，可以通过以下两个方法在属性设置前后调用

```
- (void)willChangeValueForKey:(NSString *)key
- (void)didChangeValueForKey:(NSString *)key
```

代码实现如下：

```
- (void)setName:(NSString *)name {
    [self willChangeValueForKey:@"name"];
    _name = name;
    [self didChangeValueForKey:@"name"];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"name"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}
```

手动实现属性的setter方法，并在设置操作的前后分别调用willChangeValueForKey和didChangeValueForKey，这两个方法用于通知系统该key的属性值将以及已经改变。然后在automaticallyNotifiesObserversForKey方法中，将对应的key不自动发送通知。这样操作的话，可以收到通知，同时runtime也不会生成NSKVONotifying_的类。



#### 2.3 KVO的实现原理

KVO是通过isa-swizzling实现的，基本的流程就是编译器自动为被观察对象创造一个派生类，并将被观察对象的isa指向该派生类，如果用户注册了对此目标对象的某一个属性的观察，那么该派生类会重写这个方法，并在其中添加通知的代码。OC在发送消息的时候，会通过isa指针找到当前对象所属的类对象，而类对象中保存着当前对象的实例方法，因此在向该对象发送消息的时候，实际上是发送到了派生类对象的方法。由于编译器对派生类的方法进行了重写，并添加了通知代码，所以会向注册的对象发送通知。注意派生类只重写注册了观察者的属性方法。

即当一个类型为ObjectA的对象被添加了观察后，系统会生成一个NSKVONotifying_ObjectA类，并将对象的isa指向该类，通过代码我们看一下会重写什么类。代码如下：

```
TestObject *test7 = [[TestObject alloc] init];
[test7 addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
 
NSLog(@"object:%@ - class:%@ - isaClass:%@", test7, [test7 class], [NSString stringWithUTF8String:object_getClassName(test7)]);

//将class中的方法名打印
Class class = object_getClass(test7);
    
unsigned int count;
Method *methodList = class_copyMethodList(class, &count);
for (int i = 0; i < count; i++) {
    SEL methodSEL = method_getName(methodList[i]);
    const char *name = sel_getName(methodSEL);
    NSLog(@"method name:%@", [NSString stringWithUTF8String:name]);

}

//将class的父类打印
Class superClass = class_getSuperclass(class);
const char *superClassName = class_getName(superClass);
NSLog(@"superClassName : %@ ", [NSString stringWithUTF8String:superClassName]);
```

打印结果如下：

```
object:<TestObject: 0x6000026453b0> - class:TestObject - isaClass:NSKVONotifying_TestObject

method name:setName:
method name:class
method name:dealloc
method name:_isKVOA

superClassName : TestObject
```



根据上述的打印中可以看出来，生成了一个NSKVONotifying_TestObject类，同时打印方法列表有四个方法。最后打印父类时，是对象最开始指向的类，说明了生成的衍生类为原本类的子类。



**重写setName方法**

会重写setName方法

```
- (void)setName:(NSString *)name {
    [self _NSSetIntValueAndNotify];
}

- (void)_NSSetIntValueAndNotify{
    //将要修改name的值
    [self willChangeValueForKey:@"name"];
    //调用父类的setAge方法去修改age的值
    [super setName:name];
    //完成修改name的值，并且执行observeValueForKeyPath方法
    [self didChangeValueForKey:@"name"];
}

```

主要是在原本设置属性的前后添加了willChangeValueForKey和didChangeValueForKey方法。



**重写class方法**

会将原本的类对象返回回去，这样外部调用class获取类对象时，还是显示为原来的类对象，估计是苹果不想让外部知道多了一个衍生类。

```
- (Class)class {
	return [TestObject class];
}
```



**重写dealloc方法**

重写dealloc来释放资源



**重写_isKVOA**

这个私有方法是用来表示该类是一个通过KVO机制声明的类