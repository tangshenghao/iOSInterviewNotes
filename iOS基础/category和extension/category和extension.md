## category和extension

### 1 category

#### 1.1 category简介

category是Objective-C 2.0之后添加的语言特性，category的主要作用是为已经存在的类添加方法。除此之外，category的另外的使用场景：

- 可以把类的实现分开在几个不同的文件里面。可以减少单个文件的体积。可以把不同的功能组织到不同的category里。可以由多个开发者共同完成一个类。可以按需加载想要的category等等。
- 声明私有方法。
- 模拟多继承。
- 把framework的私有方法公开。



#### 1.2 category使用和注意事项

在新建文件中，选择Objective-C文件，然后选择要生成分类的类以及分类的名字，完成后生成 类名+分类名.h和.m文件。

调用时，可以直接import该分类的头文件，相当于引用了原本的类和分类，可以用原本的类实例化以及调用分类定义的方法。

注意事项如下：

1. 分类只能增加方法，不能增加成员变量。
2. 分类方法实现中可以访问原来类中声明的成员变量。
3. 分类可以重新实现原来类中的方法，但是会覆盖掉原来的方法，会导致原来的方法没法调用（实际上还存在，只不过查找方法时，会先按顺序查找到分类的方法从而执行，如果遍历到方法列表的最后，可以执行回原本的方法）
4. 当分类、原本类、原本类的父类中有相同的方法时，方法调用的优先级：分类（按参与编译的分类有限）- 原本类 - 父类。
5. category是在runtime时加载的，不是在编译的时候。



#### 1.2 category和extension

extension看起来很像一个匿名的category，但是extension和有名字的category几乎不一样，extension是在编译期就完成，它是类的一部分，在编译期和头文件里的@interface以及实现文件里的@implement一起形成一个完整的类，伴随类的产生而产生，也一起消亡。extension一般用来隐藏类的私有信息，你必须有一个类的源码才能为一个类添加extension，所以你无法为系统的类添加extension。

但是category是在运行期完成的，其中，extension可以添加实例变量，而category无法添加，因为在运行期，对象的内存布局已经确定，如果添加实例变量就会破坏类的内部布局。在objc_class的结构体中，ivars是成员变量的列表，methodLists是指向方法列表的指针，在runtime中，结构体的大小是固定的。但方法列表是一个二维数组，所以可以修改内存区域的值，因为存储的是指针。所以可以动态添加方法，但是不能添加成员变量。



#### 1.3 category的结构

经过编译器转换，category是category_t的结构体，结构代码如下：

```
typedef struct category_t {
    const char *name;
    classref_t cls;
    struct method_list_t *instanceMethods;
    struct method_list_t *classMethods;
    struct protocol_list_t *protocols;
    struct property_list_t *instanceProperties;
} category_t;
```

对应的说明如下：

- 类的说明（name）
- 类（cls）
- category中所有给类添加的实例方法的列表（instanceMethods）
- category中所有添加类方法的列表（classMethods）
- category实现的所有协议的列表（protocols）
- category中添加的所有属性（instanceProperties）

从category的定义也可以看出来category可以添加实例方法、类方法和实现协议和添加属性，但不可以添加实例变量。

通过代码和编译器转换后的代码看一下做了哪些处理

定义了一个TestObject+plugin的分类。转换后的代码部分如下：

```
struct _category_t {
	const char *name;
	struct _class_t *cls;
	const struct _method_list_t *instance_methods;
	const struct _method_list_t *class_methods;
	const struct _protocol_list_t *protocols;
	const struct _prop_list_t *properties;
};

static struct _category_t _OBJC_$_CATEGORY_TestObject_$_plugin __attribute__ ((used, section ("__DATA,__objc_const"))) = 
{
	"TestObject",
	0, // &OBJC_CLASS_$_TestObject,
	(const struct _method_list_t *)&_OBJC_$_CATEGORY_INSTANCE_METHODS_TestObject_$_plugin,
	0,
	0,
	0,
};

static struct /*_method_list_t*/ {
	unsigned int entsize;  // sizeof(struct _objc_method)
	unsigned int method_count;
	struct _objc_method method_list[1];
} _OBJC_$_CATEGORY_INSTANCE_METHODS_TestObject_$_plugin __attribute__ ((used, section ("__DATA,__objc_const"))) = {
	sizeof(_objc_method),
	1,
	{{(struct objc_selector *)"testLog2", "v16@0:8", (void *)_I_TestObject_plugin_testLog2}}
};

static struct _category_t *L_OBJC_LABEL_CATEGORY_$ [1] __attribute__((used, section ("__DATA, __objc_catlist,regular,no_dead_strip")))= {
	&_OBJC_$_CATEGORY_TestObject_$_plugin,
};
static struct IMAGE_INFO { unsigned version; unsigned flag; } _OBJC_IMAGE_INFO = { 0, 2 };
```

其中OBJC_$_CATEGORY_INSTANCE_METHODS_TestObject_$_plugin是生成的实例方法的方法列表，里面有定义的TestLog2的方法，

category_t OBJC_$_CATEGORY_TestObject_$_plugin 是初始化生成对应的结构体。

最后编译器在DATA段下的__objc_catlist里保存了一个大小为1的category_t数组。用于运行期的加载。



#### 1.4 category加载

在运行期中，在objc-os.mm文件中：

```
void _objc_init(void)
{
    static bool initialized = false;
    if (initialized) return;
    initialized = true;

    // fixme defer initialization until an objc-using image is found?
    environ_init();
    tls_init();
    lock_init();
    exception_init();

    // Register for unmap first, in case some +load unmaps something
    _dyld_register_func_for_remove_image(&unmap_image);
    dyld_register_image_state_change_handler(dyld_image_state_bound,
                                             1/*batch*/, &map_images);
    dyld_register_image_state_change_handler(dyld_image_state_dependents_initialized, 0/*not batch*/, &load_images);
}
```

category被附加到类上面是在map_images的时候发生的，在objc_init里面的调用map_images最终会调用objc-runtime-new.mm里面的read_images方法，而在read_images方法的结尾，有以下代码：

```
// Discover categories. 
    for (EACH_HEADER) {
        category_t **catlist =
            _getObjc2CategoryList(hi, &count);
        for (i = 0; i < count; i++) {
            category_t *cat = catlist[i];
            class_t *cls = remapClass(cat->cls);

            if (!cls) {
                // Category's target class is missing (probably weak-linked).
                // Disavow any knowledge of this category.
                catlist[i] = NULL;
                if (PrintConnecting) {
                    _objc_inform("CLASS: IGNORING category \?\?\?(%s) %p with "
                                 "missing weak-linked target class",
                                 cat->name, cat);
                }
                continue;
            }

            // Process this category. 
            // First, register the category with its target class. 
            // Then, rebuild the class's method lists (etc) if 
            // the class is realized. 
            BOOL classExists = NO;
            if (cat->instanceMethods ||  cat->protocols 
                ||  cat->instanceProperties)
            {
                addUnattachedCategoryForClass(cat, cls, hi);
                if (isRealized(cls)) {
                    remethodizeClass(cls);
                    classExists = YES;
                }
                if (PrintConnecting) {
                    _objc_inform("CLASS: found category -%s(%s) %s",
                                 getName(cls), cat->name,
                                 classExists ? "on existing class" : "");
                }
            }

            if (cat->classMethods  ||  cat->protocols 
                /* ||  cat->classProperties */)
            {
                addUnattachedCategoryForClass(cat, cls->isa, hi);
                if (isRealized(cls->isa)) {
                    remethodizeClass(cls->isa);
                }
                if (PrintConnecting) {
                    _objc_inform("CLASS: found category +%s(%s)",
                                 getName(cls), cat->name);
                }
            }
        }
    }
```

其中catlist就是上节中讲到的编译器准备的category_t数组，然后后面的代码意思是

- 把category的实例方法、协议以及属性添加到类上
- 把category的类方法和协议添加到元类上

具体是如何加载到类上，remethodizeClass方法的实现代码如下：

```
static void remethodizeClass(class_t *cls)
{
    category_list *cats;
    BOOL isMeta;

    rwlock_assert_writing(&runtimeLock);

    isMeta = isMetaClass(cls);

    // Re-methodizing: check for more categories
    if ((cats = unattachedCategoriesForClass(cls))) {
        chained_property_list *newproperties;
        const protocol_list_t **newprotos;

        if (PrintConnecting) {
            _objc_inform("CLASS: attaching categories to class '%s' %s",
                         getName(cls), isMeta ? "(meta)" : "");
        }

        // Update methods, properties, protocols

        BOOL vtableAffected = NO;
        attachCategoryMethods(cls, cats, &vtableAffected);

        newproperties = buildPropertyList(NULL, cats, isMeta);
        if (newproperties) {
            newproperties->next = cls->data()->properties;
            cls->data()->properties = newproperties;
        }

        newprotos = buildProtocolList(cats, NULL, cls->data()->protocols);
        if (cls->data()->protocols  &&  cls->data()->protocols != newprotos) {
            _free_internal(cls->data()->protocols);
        }
        cls->data()->protocols = newprotos;

        _free_internal(cats);

        // Update method caches and vtables
        flushCaches(cls);
        if (vtableAffected) flushVtables(cls);
    }
}
```

其中调用的attachCategoryMethods，源码如下：

```
static void 
attachCategoryMethods(class_t *cls, category_list *cats,
                      BOOL *inoutVtablesAffected)
{
    if (!cats) return;
    if (PrintReplacedMethods) printReplacements(cls, cats);

    BOOL isMeta = isMetaClass(cls);
    method_list_t **mlists = (method_list_t **)
        _malloc_internal(cats->count * sizeof(*mlists));

    // Count backwards through cats to get newest categories first
    int mcount = 0;
    int i = cats->count;
    BOOL fromBundle = NO;
    while (i--) {
        method_list_t *mlist = cat_method_list(cats->list[i].cat, isMeta);
        if (mlist) {
            mlists[mcount++] = mlist;
            fromBundle |= cats->list[i].fromBundle;
        }
    }

    attachMethodLists(cls, mlists, mcount, NO, fromBundle, inoutVtablesAffected);

    _free_internal(mlists);

}
```

attachCategoryMethods中，把所有category的实例方法列表拼接成了一个大的实例方法列表，然后转给attachMethodLists方法。

```
for (uint32_t m = 0;
             (scanForCustomRR || scanForCustomAWZ)  &&  m < mlist->count;
             m++)
        {
            SEL sel = method_list_nth(mlist, m)->name;
            if (scanForCustomRR  &&  isRRSelector(sel)) {
                cls->setHasCustomRR();
                scanForCustomRR = false;
            } else if (scanForCustomAWZ  &&  isAWZSelector(sel)) {
                cls->setHasCustomAWZ();
                scanForCustomAWZ = false;
            }
        }

        // Fill method list array
        newLists[newCount++] = mlist;
    .
    .
    .

    // Copy old methods to the method list array
    for (i = 0; i < oldCount; i++) {
        newLists[newCount++] = oldLists[i];
    }
```

其中，添加的方法不会覆盖原先同名的方法，会在方法列表中存在两个同名方法，调用的时候，顺序查找，会先找到category的方法。上述中也有提到。



#### 1.5 category和+load方法

因为分类中可以实现+load方法，所以+load方法会按照以下顺序执行：

原本类。

再到category，而多个category是按照编译的顺序来执行的。

然后可以在原本类的load方法内调用category的方法，因为加载category的处理在load之前。



#### 1.6 category和关联对象

category中无法添加成员变量，也不会生成setter和getter方法。但是可以通过关联对象来实现和类一样的属性操作。

代码如下：

```
//.h
@interface TestObject (plugin)

@property (nonatomic, copy) NSString *testString;

@end

//.m 
#import <objc/runtime.h>

@implementation TestObject (plugin)

- (NSString *)testString {
    return objc_getAssociatedObject(self, @"testString");
}

- (void)setTestString:(NSString *)testString {
    return objc_setAssociatedObject(self, @"testString", testString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
```

关联对象是由AssociationsManager管理的，AssociationsManager是由一个静态hashMap来存储所有的关联对象，这相当于关联对象都存储在一个全局的map里面。而map的key是这个对象的指针地址，value是另外一个HashMap，里面保存了关联对象的键值对。在对象销毁时，runtime的销毁对象函数objc_destructInstance里面会判断这个对象有没有关联对象，如果有的话就会调用_object_remove_assocations做关联对象的清理工作。

```
void *objc_destructInstance(id obj) 
{
    if (obj) {
        Class isa_gen = _object_getClass(obj);
        class_t *isa = newcls(isa_gen);

        // Read all of the flags at once for performance.
        bool cxx = hasCxxStructors(isa);
        bool assoc = !UseGC && _class_instancesHaveAssociatedObjects(isa_gen);

        // This order is important.
        if (cxx) object_cxxDestruct(obj);
        if (assoc) _object_remove_assocations(obj);

        if (!UseGC) objc_clear_deallocating(obj);
    }

    return obj;
}
```

