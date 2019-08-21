# Tracer

工程静态检查-查找工程内没有使用的Class

## ENV

Swift 5.0

## Installtion

```sh
curl "https://raw.githubusercontent.com/FelixScat/Tracer/master/install.sh" | /bin/sh
Tracer --help
```

## Usage

1. cd 需要检查的目录
2. Tracer `Enter`
3. 默认会输出文档 `Tracer[X].txt`

## Example

```sh
cd XXX
Tracer --ignore-suffix XXX --ignore-prefix XXX
```

## Doc

### 静态检查工具分析

目前比较常用的几种检查工具如下

- OCLint
- Infer
- AppCode
- fui
- SameCodeFinder

我们的需求是删除没有用到的类，从而达到App瘦身的目的

上面符合我们需求的工具有两个，fui 与 AppCode

其中 AppCode 在代码检查时所需时间过多，无法持续集成

### fui

fui 的检测方式是由源代码扫描出 import 的类，和工程中所有的类做差集来获取无用的代码，感觉准确度有一些偏差

### 我的思路

在`Objective-C`工程中，我们可以将 Class 分解为几个部分

1. interface部分

```objective-c
@interface SomeClass : SuperClass

@property (strong, nonatomic) SomeType *anyObject;

@end
```

2. implement部分

```objective-c
@implementation SomeClass
- (instancetype)init {
    if (self = [super init]) {

    }    
    return self;
}
- (void)someInstanceMethod {
 		 [self dosomething];
}
+ (void)someClassMethod {
  
}
@end
```

3. protocol部分

```objective-c
@protocol SomeDelegate <NSObject>

@required
- (void)someRequiredMethod;

@optional
- (void)someOptionalMethod;

@end
```

4. category部分

```objective-c
@interface SomeClass (SomeCategory)

- (void)methodA;

@end
```

5. extension部分

```objective-c
@interface SomeClass ()

@end
```



### 解决方案

这里的重点在于`implement`部分，我们想判断一个类没有被使用仅凭判断import是不够的，因为有可能在import过后的某一次commit里面，重构或删除了部分代码，但相应的import并没有删除，在Objective-C中使用某个类的时候就会调用相关的方法发送消息, 则必有如下的调用形式在implement中出现

```objective-c
[SomeClass someMethod];
```

我们把这一次调用称作 invoke ，因此，方案基本确定，找出所有invoker中的调用者就可以了，但是还有一个事情需要我们考虑，那就是对请求数据序列化的时候，我们大多使用了如 YYModel 等第三方框架进行解析，这就需要我们把interface部分一并解析出来，获取成员属性的类型

```objective-c
@property (strong, nonatomic) SomeType *anyObject;
```

### 具体实现

既然大概思路确定了，首先我们需要生成一个命令行工程，取一个名字 Tracer

```sh
mkdir Tracer
cd Tracer
swift package init --type executable
```

工程已经建好了，现在我们需要考虑这整个过程了，把这个解析的的步骤拆分为如下几步

1. 获取输入的Objective-C文件
2. 将文件切割为Token
3. 根据Token解析出所有Interface和implement
4. 获取所有被使用的类，与全部的类做差集

