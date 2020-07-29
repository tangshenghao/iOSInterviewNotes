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

   ```
   - (instancetype)initWithBundleURL:(NSURL *)bundleURL
                          moduleName:(NSString *)moduleName
                   initialProperties:(NSDictionary *)initialProperties
                       launchOptions:(NSDictionary *)launchOptions
   {
     RCTBridge *bridge = [[RCTBridge alloc] initWithBundleURL:bundleURL
                                               moduleProvider:nil
                                                launchOptions:launchOptions];
   
     return [self initWithBridge:bridge moduleName:moduleName initialProperties:initialProperties];
   }
   ```

2. 创建RCTBridge，用于管理JS和OC的交互，做中转。

   ```
   - (instancetype)initWithDelegate:(id<RCTBridgeDelegate>)delegate
                          bundleURL:(NSURL *)bundleURL
                     moduleProvider:(RCTBridgeModuleListProvider)block
                      launchOptions:(NSDictionary *)launchOptions
   {
     if (self = [super init]) {
       _delegate = delegate;
       _bundleURL = bundleURL;
       _moduleProvider = block;
       _launchOptions = [launchOptions copy];
   
       [self setUp];
     }
     return self;
   }
   ```

3. 在RCTBridge中创建RCTCxxBridge，该类是RCTBridge的子类。JS和OC的具体交互都在这个类中实现。RCTCxxBridge没有.h文件，是在RCTBridge的分类中定义的。

   ```
   self.batchedBridge = [[bridgeClass alloc] initWithParentBridge:self];
   [self.batchedBridge start];
   ```

4. 接着执行RCTCxxBridge实例的start方法，initializeModules加载所有定义的Module

   ```
   [self registerExtraModules];
     // Initialize all native modules that cannot be loaded lazily
     (void)[self _initializeModules:RCTGetModuleClasses() withDispatchGroup:prepareBridge lazilyDiscovered:NO];
     [self registerExtraLazyModules];
   
     [_performanceLogger markStopForTag:RCTPLNativeModuleInit];
   ```

5. 往JS中插入OC模块表，这块具体代码未能关联起来，还待观察。

6. 接着调用loadSource加载JS源码，内部是RCTJavaScriptLoader调用loadBundleAtURL。

   ```
   [RCTJavaScriptLoader loadBundleAtURL:self.bundleURL onProgress:onProgress onComplete:^(NSError *error, RCTSource *source) {
     if (error) {
       RCTLogError(@"Failed to load bundle(%@) with error:(%@ %@)", self.bundleURL, error.localizedDescription, error.localizedFailureReason);
       return;
     }
     onSourceLoad(error, source);
   }];
   ```

7. 最后加载完成之后，executeSourceCode执行源代码。

   ```
   dispatch_group_notify(prepareBridge, dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
     RCTCxxBridge *strongSelf = weakSelf;
     if (sourceCode && strongSelf.loading) {
       [strongSelf executeSourceCode:sourceCode sync:NO];
     }
   });
   ```

8. 执行完后主线程通知回调

   ```
   dispatch_async(dispatch_get_main_queue(), ^{
     [[NSNotificationCenter defaultCenter]
      postNotificationName:RCTJavaScriptDidLoadNotification
      object:self->_parentBridge userInfo:@{@"bridge": self}];
   
     // Starting the display link is not critical to startup, so do it last
     [self ensureOnJavaScriptThread:^{
       // Register the display link to start sending js calls after everything is setup
       [self->_displayLink addToRunLoop:[NSRunLoop currentRunLoop]];
     }];
   });
   ```

9. 执行UI渲染

<br />

### 4 React-Native加载JS源码

1. 通过URL加载JS代码。

   ```
   [RCTJavaScriptLoader loadBundleAtURL:self.bundleURL onProgress:onProgress onComplete:^(NSError *error, RCTSource *source) {
     if (error) {
       RCTLogError(@"Failed to load bundle(%@) with error:(%@ %@)", self.bundleURL, error.localizedDescription, error.localizedFailureReason);
       return;
     }
     onSourceLoad(error, source);
   }];
   ```

2. 开启异步加载jS代码。

   ```
   // 加载本地
   NSData *data = [self attemptSynchronousLoadOfBundleAtURL:scriptURL
                                             runtimeBCVersion:JSNoBytecodeFileFormatVersion
                                                 sourceLength:&sourceLength
                                                        error:&error];
   if (data) {
     onComplete(nil, RCTSourceCreate(scriptURL, data, sourceLength));
     return;
   }
   
   // 加载网络服务
   const BOOL isCannotLoadSyncError =
     [error.domain isEqualToString:RCTJavaScriptLoaderErrorDomain]
     && error.code == RCTJavaScriptLoaderErrorCannotBeLoadedSynchronously;
   
     if (isCannotLoadSyncError) {
       attemptAsynchronousLoadOfBundleAtURL(scriptURL, onProgress, onComplete);
     } else {
       onComplete(error, nil);
     }
   ```

3. 让中间对象执行源代码

   ```
   [strongSelf executeSourceCode:sourceCode sync:NO];
   ```

4. 上面的方法最终将给到JS执行者执行源码

   ```
   // m_jse 的类是 遵循<RCTJavaScriptExecutor>的类
   [m_jse executeApplicationScript:[NSData dataWithBytes:script->c_str() length:script->size()]
        sourceURL:[[NSURL alloc]
                      initWithString:@(sourceURL.c_str())]
        onComplete:^(NSError *error) {
     RCTProfileEndFlowEvent();
   
     if (error) {
       m_errorBlock(error);
       return;
     }
   
     [m_jse flushedQueue:m_jsCallback];
   }];
   ```

5. 执行加载后回调到上层进行通知

   ```
   [[NSNotificationCenter defaultCenter]
          postNotificationName:RCTJavaScriptDidLoadNotification
          object:self->_parentBridge userInfo:@{@"bridge": self}];
   ```

6. RCTRootView收到通知，创建RCTRootContentView

   ```
   - (void)javaScriptDidLoad:(NSNotification *)notification
   {
     RCTAssertMainQueue();
   
     // Use the (batched) bridge that's sent in the notification payload, so the
     // RCTRootContentView is scoped to the right bridge
     RCTBridge *bridge = notification.userInfo[@"bridge"];
     if (bridge != _contentView.bridge) {
       [self bundleFinishedLoading:bridge];
     }
   }
   
   - (void)bundleFinishedLoading:(RCTBridge *)bridge
   {
     RCTAssert(bridge != nil, @"Bridge cannot be nil");
     if (!bridge.valid) {
       return;
     }
   
     [_contentView removeFromSuperview];
     _contentView = [[RCTRootContentView alloc] initWithFrame:self.bounds
                                                       bridge:bridge
                                                     reactTag:self.reactTag
                                               sizeFlexiblity:_sizeFlexibility];
     [self runApplication:bridge];
   
     _contentView.passThroughTouches = _passThroughTouches;
     [self insertSubview:_contentView atIndex:0];
   
     if (_sizeFlexibility == RCTRootViewSizeFlexibilityNone) {
       self.intrinsicContentSize = self.bounds.size;
     }
   }
   ```

7. 通知JS运行APP，让RCTCxxBridge执行JS调用AppRegistry方法

   ```
   - (void)runApplication:(RCTBridge *)bridge
   {
     NSString *moduleName = _moduleName ?: @"";
     NSDictionary *appParameters = @{
       @"rootTag": _contentView.reactTag,
       @"initialProps": _appProperties ?: @{},
     };
   
     RCTLogInfo(@"Running application %@ (%@)", moduleName, appParameters);
     [bridge enqueueJSCall:@"AppRegistry"
                    method:@"runApplication"
                      args:@[moduleName, appParameters]
                completion:NULL];
   }
   ```

8. 上述最后是到RCTWebSocketExecutor中，去通过websocket发送信息

   ```
   - (void)sendMessage:(NSDictionary<NSString *, id> *)message onReply:(RCTWSMessageCallback)callback
   {
     static NSUInteger lastID = 10000;
   
     if (_setupError) {
       callback(_setupError, nil);
       return;
     }
   
     dispatch_async(_jsQueue, ^{
       if (!self.valid) {
         callback(RCTErrorWithMessage(@"Runtime is not ready for debugging. Make sure Packager server is running."), nil);
         return;
       }
   
       NSNumber *expectedID = @(lastID++);
       self->_callbacks[expectedID] = [callback copy];
       NSMutableDictionary<NSString *, id> *messageWithID = [message mutableCopy];
       messageWithID[@"id"] = expectedID;
       [self->_socket send:RCTJSONStringify(messageWithID, NULL)];
     });
   }
   ```

9. 调用runApplication后，然后启动显示链去执行渲染。

   ```
   [self ensureOnJavaScriptThread:^{
     [self->_displayLink addToRunLoop:[NSRunLoop currentRunLoop]];
   }];
   ```

<br />

### 5 React-Native UI控件渲染流程

在RCTCxxBridge的start中，设置了RCTInstanceCallback，内部有onBatchComplete的回调。内部会执行batchDidComplete。

但是我翻了很久没有找到哪里执行了回调。

所以直接从batchDidComplete开始。

1. batchDidComplete内部循环会让遵循RCTBridgeModule协议的类执行batchDidComplete

2. 会在RCTUIManager中执行_layoutAndMount

3. 方法内部设置了动画布局，设置UIBlock。

4. JS执行OC代码，让UI管理者创建子控件View

   ```
   RCT_EXPORT_METHOD(createView:(nonnull NSNumber *)reactTag
                     viewName:(NSString *)viewName
                     rootTag:(nonnull NSNumber *)rootTag
                     props:(NSDictionary *)props)
   {
     RCTComponentData *componentData = _componentDataByName[viewName];
     if (componentData == nil) {
       RCTLogError(@"No component found for view with name \"%@\"", viewName);
     }
   	// 注册shadow View
     // Register shadow view
     RCTShadowView *shadowView = [componentData createShadowViewWithT0ag:reactTag];
     if (shadowView) {
       [componentData setProps:props forShadowView:shadowView];
       _shadowViewRegistry[reactTag] = shadowView;
       RCTShadowView *rootView = _shadowViewRegistry[rootTag];
       RCTAssert([rootView isKindOfClass:[RCTRootShadowView class]] ||
                 [rootView isKindOfClass:[RCTSurfaceRootShadowView class]],
         @"Given `rootTag` (%@) does not correspond to a valid root shadow view instance.", rootTag);
       shadowView.rootView = (RCTRootShadowView *)rootView;
     }
   
     // Dispatch view creation directly to the main thread instead of adding to
     // UIBlocks array. This way, it doesn't get deferred until after layout.
     __block UIView *preliminaryCreatedView = nil;
   
     void (^createViewBlock)(void) = ^{
       // Do nothing on the second run.
       if (preliminaryCreatedView) {
         return;
       }
   
       preliminaryCreatedView = [componentData createViewWithTag:reactTag];
   
       if (preliminaryCreatedView) {
         self->_viewRegistry[reactTag] = preliminaryCreatedView;
       }
     };
   
     // We cannot guarantee that asynchronously scheduled block will be executed
     // *before* a block is added to the regular mounting process (simply because
     // mounting process can be managed externally while the main queue is
     // locked).
     // So, we positively dispatch it asynchronously and double check inside
     // the regular mounting block.
   
     RCTExecuteOnMainQueue(createViewBlock);
   
     [self addUIBlock:^(__unused RCTUIManager *uiManager, __unused NSDictionary<NSNumber *, UIView *> *viewRegistry) {
       createViewBlock();
   
       if (preliminaryCreatedView) {
         [componentData setProps:props forView:preliminaryCreatedView];
       }
     }];
   
     [self _shadowView:shadowView didReceiveUpdatedProps:[props allKeys]];
   }
   ```

5. JS给RCTRootView对应的RCTRootShadowView设置子控件

   ```
   RCT_EXPORT_METHOD(setChildren:(nonnull NSNumber *)containerTag
                     reactTags:(NSArray<NSNumber *> *)reactTags)
   {
     RCTSetChildren(containerTag, reactTags,
                    (NSDictionary<NSNumber *, id<RCTComponent>> *)_shadowViewRegistry);
   
     [self addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
   
       RCTSetChildren(containerTag, reactTags,
                      (NSDictionary<NSNumber *, id<RCTComponent>> *)viewRegistry);
     }];
   
     [self _shadowViewDidReceiveUpdatedChildren:_shadowViewRegistry[containerTag]];
   }
   ```

6. 上述方法中会遍历子控件数组，给RCTRootShadowView插入所有子控件

   ```
   static void RCTSetChildren(NSNumber *containerTag,
                              NSArray<NSNumber *> *reactTags,
                              NSDictionary<NSNumber *, id<RCTComponent>> *registry)
   {
     id<RCTComponent> container = registry[containerTag];
     NSInteger index = 0;
     for (NSNumber *reactTag in reactTags) {
       id<RCTComponent> view = registry[reactTag];
       if (view) {
         [container insertReactSubview:view atIndex:index++];
       }
     }
   }
   ```

   

7. _layoutAndMount中的dispatchChildrenDidChangeEvents的UIBlock会执行didUpdateReactSubviews给原生添加子控件。

   ```
   [self addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
       for (NSNumber *tag in tags) {
         UIView<RCTComponent> *view = viewRegistry[tag];
         [view didUpdateReactSubviews];
       }
   }];
   
   // 最终执行到RCTView或其他RN原生View中的react_updateClippedSubviewsWithClipRect
   - (void)react_updateClippedSubviewsWithClipRect:(CGRect)clipRect relativeToView:(UIView *)clipView
   {
     // TODO (#5906496): for scrollviews (the primary use-case) we could
     // optimize this by only doing a range check along the scroll axis,
     // instead of comparing the whole frame
   
     if (!_removeClippedSubviews) {
       // Use default behavior if unmounting is disabled
       return [super react_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
     }
   
     if (self.reactSubviews.count == 0) {
       // Do nothing if we have no subviews
       return;
     }
   
     if (CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
       // Do nothing if layout hasn't happened yet
       return;
     }
   
     // Convert clipping rect to local coordinates
     clipRect = [clipView convertRect:clipRect toView:self];
     clipRect = CGRectIntersection(clipRect, self.bounds);
     clipView = self;
   
     // Mount / unmount views
     for (UIView *view in self.reactSubviews) {
       if (!CGSizeEqualToSize(CGRectIntersection(clipRect, view.frame).size, CGSizeZero)) {
         // View is at least partially visible, so remount it if unmounted
         [self addSubview:view];
   
         // Then test its subviews
         if (CGRectContainsRect(clipRect, view.frame)) {
           // View is fully visible, so remount all subviews
           [view react_remountAllSubviews];
         } else {
           // View is partially visible, so update clipped subviews
           [view react_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
         }
   
       } else if (view.superview) {
   
         // View is completely outside the clipRect, so unmount it
         [view removeFromSuperview];
       }
     }
   }
   ```

8. 完成UI渲染

<br />

### 6 React-Native 事件处理流程

1. 初始化RCTRootContentView时，创建了RCTTouchHandler，此类继承自UIGestureRecognizer，实现了手势事件的方法。

2. RCTTouchHandler的初始化方法中，从bridge的mudules中取出了RCTEventDispatcher类，此类用于处理事件传递给JS。

   ```
   - (void)_updateAndDispatchTouches:(NSSet<UITouch *> *)touches
                           eventName:(NSString *)eventName
   {
     // Update touches
     NSMutableArray<NSNumber *> *changedIndexes = [NSMutableArray new];
     for (UITouch *touch in touches) {
       NSInteger index = [_nativeTouches indexOfObject:touch];
       if (index == NSNotFound) {
         continue;
       }
   
       [self _updateReactTouchAtIndex:index];
       [changedIndexes addObject:@(index)];
     }
   
     if (changedIndexes.count == 0) {
       return;
     }
   
     // Deep copy the touches because they will be accessed from another thread
     // TODO: would it be safer to do this in the bridge or executor, rather than trusting caller?
     NSMutableArray<NSDictionary *> *reactTouches =
     [[NSMutableArray alloc] initWithCapacity:_reactTouches.count];
     for (NSDictionary *touch in _reactTouches) {
       [reactTouches addObject:[touch copy]];
     }
   
     BOOL canBeCoalesced = [eventName isEqualToString:@"touchMove"];
   
     // We increment `_coalescingKey` twice here just for sure that
     // this `_coalescingKey` will not be reused by another (preceding or following) event
     // (yes, even if coalescing only happens (and makes sense) on events of the same type).
   
     if (!canBeCoalesced) {
       _coalescingKey++;
     }
   
     RCTTouchEvent *event = [[RCTTouchEvent alloc] initWithEventName:eventName
                                                            reactTag:self.view.reactTag
                                                        reactTouches:reactTouches
                                                      changedIndexes:changedIndexes
                                                       coalescingKey:_coalescingKey];
   
     if (!canBeCoalesced) {
       _coalescingKey++;
     }
   	// 发送事件到JS中
     [_eventDispatcher sendEvent:event];
   }
   ```

3. 通过RCTRootContentView截获点击事件。

   ```
   - (void)attachToView:(UIView *)view
   {
     RCTAssert(self.view == nil, @"RCTTouchHandler already has attached view.");
   	// 添加事件监听
     [view addGestureRecognizer:self];
   }
   ```

4. 截获到事件后，在sendEvent方法中会生成RCTTouchEvent事件对象，让事件分发对象调用事件对象，把事件保存到事件队列中。

   ```
   [_eventQueueLock lock];
   
   NSNumber *eventID = RCTGetEventID(event);
   
   id<RCTEvent> previousEvent = _events[eventID];
   if (previousEvent) {
     RCTAssert([event canCoalesce], @"Got event %@ which cannot be coalesced, but has the same eventID %@ as the previous event %@", event, eventID, previousEvent);
     event = [previousEvent coalesceWithEvent:event];
   } else {
     [_eventQueue addObject:eventID];
   }
   _events[eventID] = event;
   
   BOOL scheduleEventsDispatch = NO;
   if (!_eventsDispatchScheduled) {
     _eventsDispatchScheduled = YES;
     scheduleEventsDispatch = YES;
   }
   
   // We have to release the lock before dispatching block with events,
   // since dispatchBlock: can be executed synchronously on the same queue.
   // (This is happening when chrome debugging is turned on.)
   [_eventQueueLock unlock];
   ```

5. 执行队列中的所有事件

   ```
   if (scheduleEventsDispatch) {
       [_bridge dispatchBlock:^{
         [self flushEventsQueue];
       } queue:RCTJSThread];
     }
   ```

6. 遍历事件队列，一个一个分发执行事件，实际上就是执行JS代码中的相应事件。

   ```
   - (void)flushEventsQueue
   {
     [_eventQueueLock lock];
     NSDictionary *events = _events;
     _events = [NSMutableDictionary new];
     NSMutableArray *eventQueue = _eventQueue;
     _eventQueue = [NSMutableArray new];
     _eventsDispatchScheduled = NO;
     [_eventQueueLock unlock];
   
     for (NSNumber *eventId in eventQueue) {
       [self dispatchEvent:events[eventId]];
     }
   }
   ```

7. 让brigde对象调用JS处理事件

   ```
   - (void)dispatchEvent:(id<RCTEvent>)event
   {
     [_bridge enqueueJSCall:[[event class] moduleDotMethod] args:[event arguments]];
   }
   ```

8. 最后就通过RCTCxxBrigde将事件传递到JS中执行，就能把UI事件传递到JS中。

<br />

### 7 React-Native Module注册和JS和原生交互

首先需要与RN交互的原生类，需要遵循RCTBridgeModule协议，并且实现RCT_EXPORT_MODULE宏定义。

如果需要JS调用原生代码，需要实现RCT_EXPORT_METHOD宏定义的方法。

#### 7.1 原生类的注册及获取实例

先来解析Module注册和JS调用的处理。

当遵循此类后，会在项目启动时执行load方法，对类进行注册

```
#define RCT_EXPORT_MODULE(js_name) \
RCT_EXTERN void RCTRegisterModule(Class); \
+ (NSString *)moduleName { return @#js_name; } \
+ (void)load { RCTRegisterModule(self); }
// 实现
void RCTRegisterModule(Class);
void RCTRegisterModule(Class moduleClass)
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    RCTModuleClasses = [NSMutableArray new];
    RCTModuleClassesSyncQueue = dispatch_queue_create("com.facebook.react.ModuleClassesSyncQueue", DISPATCH_QUEUE_CONCURRENT);
  });

  RCTAssert([moduleClass conformsToProtocol:@protocol(RCTBridgeModule)],
            @"%@ does not conform to the RCTBridgeModule protocol",
            moduleClass);

  // Register module
  dispatch_barrier_async(RCTModuleClassesSyncQueue, ^{
    [RCTModuleClasses addObject:moduleClass];
  });
}
```

从代码中看，就是将定义的类class存储到全局静态的数组RCTModuleClasses中。在上面的第3节start的方法中，有注册所有类的方法，也就是从RCTModuleClasses取出所有的类，然后执行每个类的实例操作。

然后在原生中取出对应的实例，是通过两个方法。

```
// 通过moduleName取出对应的实例。
- (id)moduleForName:(NSString *)moduleName
{
  return [self.batchedBridge moduleForName:moduleName];
}
// 通过moduleClass取出对应的实例
- (id)moduleForClass:(Class)moduleClass
{
  id module = [self.batchedBridge moduleForClass:moduleClass];
  if (!module) {
    module = [self moduleForName:RCTBridgeModuleNameForClass(moduleClass)];
  }
  return module;
}

// 因为注册时，已将对应的实例RCTModuleData实例存进_moduleDataByName的字典中，对应的RCTModuleData的instance就是原生类的实例
- (id)moduleForName:(NSString *)moduleName lazilyLoadIfNecessary:(BOOL)lazilyLoad
{
  if (RCTTurboModuleEnabled() && _turboModuleLookupDelegate) {
    const char* moduleNameCStr = [moduleName UTF8String];
    if (lazilyLoad || [_turboModuleLookupDelegate moduleIsInitialized:moduleNameCStr]) {
      id<RCTTurboModule> module = [_turboModuleLookupDelegate moduleForName:moduleNameCStr warnOnLookupFailure:NO];
      if (module != nil) {
        return module;
      }
    }
  }

  if (!lazilyLoad) {
    return _moduleDataByName[moduleName].instance;
  }

  RCTModuleData *moduleData = _moduleDataByName[moduleName];
  if (moduleData) {
    if (![moduleData isKindOfClass:[RCTModuleData class]]) {
      // There is rare race condition where the data stored in the dictionary
      // may have been deallocated, which means the module instance is no longer
      // usable.
      return nil;
    }
    return moduleData.instance;
  }

  // Module may not be loaded yet, so attempt to force load it here.
  const BOOL result = [self.delegate respondsToSelector:@selector(bridge:didNotFindModule:)] &&
    [self.delegate bridge:self didNotFindModule:moduleName];
  if (result) {
    // Try again.
    moduleData = _moduleDataByName[moduleName];
  } else {
    RCTLogError(@"Unable to find module for %@", moduleName);
  }

  return moduleData.instance;
}

```

<br />

#### 7.2 原生类的方法注册及调用

在原生类中，使用RCT_EXPORT_METHOD，可以挂载方法，然后提供JS进行调用。具体源码实现如下：

```
#define RCT_EXPORT_METHOD(method) \
  RCT_REMAP_METHOD(, method)
  
#define RCT_REMAP_METHOD(js_name, method) \
  _RCT_EXTERN_REMAP_METHOD(js_name, method, NO) \
  - (void)method RCT_DYNAMIC;

// 最终生成一个RCTMethodInfo的方法的对象指针，内部指向函数的地址
#define _RCT_EXTERN_REMAP_METHOD(js_name, method, is_blocking_synchronous_method) \
+ (const RCTMethodInfo *)RCT_CONCAT(__rct_export__, RCT_CONCAT(js_name, RCT_CONCAT(__LINE__, __COUNTER__))) { \
  static RCTMethodInfo config = {#js_name, #method, is_blocking_synchronous_method}; \
  return &config; \
}
```

在RCTModuleData中，methods在被调用时，会将对应的imp取出，然后生成RCTModuleMehold对象存入_methods中。

```
- (NSArray<id<RCTBridgeMethod>> *)methods
{
  if (!_methods) {
    NSMutableArray<id<RCTBridgeMethod>> *moduleMethods = [NSMutableArray new];

    if ([_moduleClass instancesRespondToSelector:@selector(methodsToExport)]) {
      [moduleMethods addObjectsFromArray:[self.instance methodsToExport]];
    }

    unsigned int methodCount;
    Class cls = _moduleClass;
    while (cls && cls != [NSObject class] && cls != [NSProxy class]) {
      Method *methods = class_copyMethodList(object_getClass(cls), &methodCount);

      for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        if ([NSStringFromSelector(selector) hasPrefix:@"__rct_export__"]) {
          IMP imp = method_getImplementation(method);
          auto exportedMethod = ((const RCTMethodInfo *(*)(id, SEL))imp)(_moduleClass, selector);
          id<RCTBridgeMethod> moduleMethod = [[RCTModuleMethod alloc] initWithExportedMethod:exportedMethod
                                                                                 moduleClass:_moduleClass];
          [moduleMethods addObject:moduleMethod];
        }
      }

      free(methods);
      cls = class_getSuperclass(cls);
    }

    _methods = [moduleMethods copy];
  }
  return _methods;
}
```

然后JS中有调用的话，通过invokeWithBridge来执行对应的方法

```
- (id)invokeWithBridge:(RCTBridge *)bridge
                module:(id)module
             arguments:(NSArray *)arguments
{
  if (_argumentBlocks == nil) {
    [self processMethodSignature];
  }

#if RCT_DEBUG
  // Sanity check
  RCTAssert([module class] == _moduleClass, @"Attempted to invoke method \
            %@ on a module of class %@", [self methodName], [module class]);

  // Safety check
  if (arguments.count != _argumentBlocks.count) {
    NSInteger actualCount = arguments.count;
    NSInteger expectedCount = _argumentBlocks.count;

    // Subtract the implicit Promise resolver and rejecter functions for implementations of async functions
    if (self.functionType == RCTFunctionTypePromise) {
      actualCount -= 2;
      expectedCount -= 2;
    }

    RCTLogError(@"%@.%s was called with %lld arguments but expects %lld arguments. "
                @"If you haven\'t changed this method yourself, this usually means that "
                @"your versions of the native code and JavaScript code are out of sync. "
                @"Updating both should make this error go away.",
                RCTBridgeModuleNameForClass(_moduleClass), self.JSMethodName,
                (long long)actualCount, (long long)expectedCount);
    return nil;
  }
#endif

  // Set arguments
  NSUInteger index = 0;
  for (id json in arguments) {
    RCTArgumentBlock block = _argumentBlocks[index];
    if (!block(bridge, index, RCTNilIfNull(json))) {
      // Invalid argument, abort
      RCTLogArgumentError(self, index, json, "could not be processed. Aborting method call.");
      return nil;
    }
    index++;
  }

  // Invoke method
#ifdef RCT_MAIN_THREAD_WATCH_DOG_THRESHOLD
  if (RCTIsMainQueue()) {
    CFTimeInterval start = CACurrentMediaTime();
    [_invocation invokeWithTarget:module];
    CFTimeInterval duration = CACurrentMediaTime() - start;
    if (duration > RCT_MAIN_THREAD_WATCH_DOG_THRESHOLD) {
      RCTLogWarn(
                 @"Main Thread Watchdog: Invocation of %@ blocked the main thread for %dms. "
                 "Consider using background-threaded modules and asynchronous calls "
                 "to spend less time on the main thread and keep the app's UI responsive.",
                 [self methodName],
                 (int)(duration * 1000)
                 );
    }
  } else {
    [_invocation invokeWithTarget:module];
  }
#else
  [_invocation invokeWithTarget:module];
#endif

  index = 2;
  [_retainedObjects removeAllObjects];

  if (_methodInfo->isSync) {
    void *returnValue;
    [_invocation getReturnValue:&returnValue];
    return (__bridge id)returnValue;
  }
  return nil;
}
```

然后在method中，是通过字符串去判断是不是promise的类型

```
- (RCTFunctionType)functionType
{
  if (strstr(_methodInfo->objcName, "RCTPromise") != NULL) {
    RCTAssert(!_methodInfo->isSync, @"Promises cannot be used in sync functions");
    return RCTFunctionTypePromise;
  } else if (_methodInfo->isSync) {
    return RCTFunctionTypeSync;
  } else {
    return RCTFunctionTypeNormal;
  }
}
```

<br />

#### 7.3 原生调用RN的方法

实现原生调用JS，需要继承RCTEventEmitter类，然后实现supportedEvents方法，里面包含原生要调用的方法名。然后调用时，执行sendEventWithName的方法。例如：

```
//挂载RN可监听的方法 使用supportedEvents的数组返回  RN内 addListener可监听到方法
- (NSArray<NSString *> *)supportedEvents {
    return @[@"onRemoteMessage"];
}

[self sendEventWithName:@"onRemoteMessage" body:body];
```

其中sendEventWithName内部实现如下：

```
- (void)sendEventWithName:(NSString *)eventName body:(id)body
{
  RCTAssert(_bridge != nil, @"Error when sending event: %@ with body: %@. "
            "Bridge is not set. This is probably because you've "
            "explicitly synthesized the bridge in %@, even though it's inherited "
            "from RCTEventEmitter.", eventName, body, [self class]);

  if (RCT_DEBUG && ![[self supportedEvents] containsObject:eventName]) {
    RCTLogError(@"`%@` is not a supported event type for %@. Supported events are: `%@`",
                eventName, [self class], [[self supportedEvents] componentsJoinedByString:@"`, `"]);
  }
  if (_listenerCount > 0) {
    [_bridge enqueueJSCall:@"RCTDeviceEventEmitter"
                    method:@"emit"
                      args:body ? @[eventName, body] : @[eventName]
                completion:NULL];
  } else {
    RCTLogWarn(@"Sending `%@` with no listeners registered.", eventName);
  }
}
```

实际上也就是通过RCTCxxBridge去执行消息的发送。

JS会在加载时去监听supportedEvents中的方法。

<br />

#### 7.4 原生提供UI组件

将原生的组件提供给RN，需要继承RCTViewManager，并且实现view方法。

```
- (UIView *)view;
```

内部实现如下：

```
// 默认是返回RCTView，子类覆盖后，返回的是原生的类
- (UIView *)view
{
#if TARGET_OS_TV
  return [RCTTVView new];
#else
  return [RCTView new];
#endif
}
```

同时内部实现了很多通用的属性实现。