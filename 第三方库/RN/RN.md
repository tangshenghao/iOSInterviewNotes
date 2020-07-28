## React-Native

### 1 React-Native简介

#### 1.1 React

React是由Facebook推出的一个JavaScript框架，主要用于前端开发。React采用组件化方式简化Web开发。

React可以高效的绘制界面，原生的Web刷新界面，需要把整个界面刷新，React只会刷新部分界面，不会整个界面刷新。React是采用JSX语法，一种语法糖，方便快速开发。

<br />

#### 1.2 Reace-Native原理

Reace-Native的实现其实是底层把React转换为原生API。React的底层需要iOS和安卓都得实现，说明React-Native底层解析原生API是分开实现的.

<br />

#### 1.3 React-Native转换原生API

React-Native会在一开始生成OC模块表，然后把这个模块表传入JS中，JS参照模块表，就能间接调用OC的代码。

<br />

### 2 React-Native JS和OC交互

iOS原生API有个JavaScriptCore框架，通过它能实现JS和OC交互。

简单流程如下：

- 首先把JSX代码写好
- 把JSX代码解析成javaScript代码
- OC读取JS文件
- 把javaScript代码读取出来，利用JavaScriptCore执行
- javaScript代码返回一个数组，数组中会描述OC对象，OC对象的属性，OC对象所需要执行的方法，这样就能让这个对象设置属性，并且调用方法。

<br />

### 3 React-Native启动流程

1. 创建RCTRootView，该View继承自UIView，也就是用于显示RN的根View。
2. 创建RCTBridge，用于管理JS和OC的交互，做中转。
3. 在RCTBridge中创建RCTCxxBridge，该类是RCTBridge的子类。JS和OC的具体交互都在这个类中实现。RCTCxxBridge没有.h文件，是在RCTBridge的分类中定义的。
4. 接着执行RCTCxxBridge实例的start方法，initializeModules加载所有定义的Module
5. 接着调用loadSource加载JS源码，内部是RCTJavaScriptLoader调用loadBundleAtURL。
6. 最后加载完成之后，executeSourceCode执行源代码。



