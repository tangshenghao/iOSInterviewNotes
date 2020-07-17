## MVVM

### 

传统的MVC分为：Model、View、Controller。MVVM模式多了一个ViewModel，作用就是为Controller减轻负担，将弱业务逻辑转到ViewModel中。MVVM的使用当中，通常还会利用双向绑定技术，使得Model变化时，ViewModel会自动更新，而ViewModel变化时，View也会自动变化。

![](https://github.com/tangshenghao/iOSInterviewNotes/blob/master/%E6%9E%B6%E6%9E%84/MVVM/MVVM.jpg?raw=true)

对于复杂的页面，MVVM最大的优势在于职责分明，能够很大程度上降低VC的压力，而且ViewModel因为抛弃了页面之间的跳转逻辑，复用起来也非常方便，单测也比较容易写。而且通常MVVM的代码风格可以保持高度一致。

但使用数据绑定使得Bug很难被调试，你看到界面异常，有可能是View的代码有问题，也有可能是Model的代码有问题。

对于过大的项目，数据绑定需要花费更多的内存。

通常实现绑定器和调度协调器，需要引入RxSwift等框架，加大了项目的额外负担。

不过也可能是我没使用过MVVM来开发项目，形成统一规范。所以才没能感受到MVVM框架的魅力吧。

