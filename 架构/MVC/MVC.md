## MVC

### 1 MVC简介

MVC，是模型 - 视图 - 控制器的缩写，表示一种常见的客户端软件开发框架。

Model：模型对象封装特定于应用程序的数据，并定义操作和处理该数据的逻辑和计算。

View：视图对象是用户可以看到的应用程序中的对象。

Controller：控制器对象充当应用程序的一个或多个视图对象与其一个或多个模型对象之间的中介。因此控制器对象是视图对象通过其获取模型对象的变化的通道，反之亦然。控制器对象还可以为应用程序执行设置和调度任务，并管理其他对象的生命周期。

苹果官方的MVP架构图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E6%9E%B6%E6%9E%84/MVC/MVC%E6%A1%86%E6%9E%B6.jpg?raw=true)

斯坦福公开课的MVP架构图：

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E6%9E%B6%E6%9E%84/MVC/MVC%E6%96%AF%E5%9D%A6%E7%A6%8F%E5%85%AC%E5%BC%80%E8%AF%BE.jpg?raw=true)

### 2 Controller的臃肿问题

其实MVC架构的特点很多时候是为了Don‘t repeat yourself原则来做的，该原则要求能够复用代码要尽量复用，来保证重用。在MVC这种设计模式中，我们发现View和Model都是符合这种原则的。

对于View来说，如果抽象得很好，那么View很容易移植到别的App上，类似github上的很多view组件就是很好的封装设计，方便复用。

对于Model来说，其实是用来存储业务的数据，如果做得好，它也可以方便地复用，不过一般Model层代码都是具有一定的业务逻辑，所以移植的话一般来说是同业务的App才便于移植。

对于Controller，是View与Model的中介，构造和调度View和Model，不容易复用。所以Controller里面只应该存放不能复用的代码，包括：

- 在初始化时，构造响应的View和Model。
- 监听Model层的事件，将Model层的数据传递到View层。

如果Controller只有以上这些代码，那么它的逻辑将非常简单，而且也会非常短。

但是一般都比较难做到这一点，因为很多逻辑都不知道写在哪里的时候，于是就都写到了Controller中。

<br />

### 3 对Controller瘦身

其实MVC虽然只有三层，但是它并没有限制只能有三层，所以可以将Controller过于臃肿的逻辑抽取出来。

#### 3.1 将网络请求抽象到单独的类中

对于网络请求，可以把每一个网络请求封装成对象，其实是使用了设计模式中的Command模式。

这样的好处是将网络请求与具体的第三库依赖隔离，方便以后更换底层的网络库。

方便在基类中处理公共逻辑和缓存逻辑。

方便做对象的持久化。

<br />

#### 3.2 将页面的拼装抽象到专门的类中

有以下两种方法：

构造专门的UIView的子类，来负责这些空间的拼装。这是最彻底和优雅的方式，不过稍微麻烦的是，你需要把这些空间的事件回调先接管，然后再暴露回Controller。

用一个静态的Util类，帮助你做UIView的拼装工作。这种方式稍微做得不太彻底，但是比较简单。

<br />

#### 3.3 构造ViewModel

可以借鉴MVVM的优点，创建一个ViewModel，将ViewController给View传递数据的过程，抽象成构造ViewModel的过程。

抽象之后，View只接受ViewModel，而Controller只需要传递ViewModel这么一行代码。而构造ViewModel的过程，我们就可以移动到另外的类中了。

可以创建构造ViewModel的工厂类，参见工厂模式。另外也可以专门将数据存取都抽到一个Service层，由这层来提供ViewModel的获取。

<br />

#### 3.4 专门构造存储类

可以将数据存取放在专门的类中，就可以针对存取做额外的事情。比如：

对一些频繁使用的数据增加缓存。

处理数据迁移相关的逻辑。

通过以上的处理，可以将MVC设计模式中的ViewController进一步拆分，构造出网络请求层、ViewModel层、Service层、Storage层等其他类，来配合Controller工作，从而使Controller更加简单。

<br />

### 4 总结

通常项目中，时间一久，就会越来越多的逻辑直接写到ViewController中，所以需要时不时的review代码，做好管控，才可以不让项目规范越来越偏离正轨。

封装好View和Model，抽象出可以复用的逻辑，尽量制作成通用的版式，方便开发人员调用和理解，在Controller层也处理好几块逻辑的拆分处理。

<br />