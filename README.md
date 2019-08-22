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
4. 获取所有被使用的类，与解析出全部的类做差集

#### 定义Token

```swift
/// Token Type
///
/// - EOF: 文件结尾
/// - unknown: 未知类型
/// - name: 单词
/// - plus: +
/// - minus: -
/// - asterisk: *
/// - forwardSlash: /
/// - backslash: \
/// - at: @
/// - atProtocol: @protocol
/// - atInterface: @interface
/// - atImplementation: @implementation
/// - atProperty: @property
/// - atEnd: @end
/// - atImport: @import
/// - atClass: @class
/// - pound: #
/// - poundImport: #import
/// - dollar: $
/// - openParen: (
/// - closeParen: )
/// - openBracket: [
/// - closeBracket: ]
/// - openBrace: {
/// - closeBrace: }
/// - less: <
/// - greater: >
/// - colon: :
/// - comma: ,
/// - semicolon: ;
/// - equal: =
/// - underline: _
/// - doubleQuotation: "
/// - caret: ^
/// - dot: .
/// - rightArrow: ->
/// - `super`: super
/// - `static`: static
/// - `return`: return
public enum TokenType {
    case EOF
    case unknown
    case name
    case plus
    case minus
    case asterisk
    case forwardSlash
    case backslash
    case at
    case atProtocol
    case atInterface
    case atImplementation
    case atProperty
    case atEnd
    case atImport
    case atClass
    case pound
    case poundImport
    case dollar
    case openParen
    case closeParen
    case openBracket
    case closeBracket
    case openBrace
    case closeBrace
    case less
    case greater
    case colon
    case comma
    case semicolon
    case equal
    case underline
    case doubleQuotation
    case caret
    case dot
    case rightArrow
    case `super`
    case `static`
    case `return`
}

public struct Token {
    public let type: TokenType
    public let text: String
}
```

定义好对应的Token后，就可以开始取词器的编写了

```swift
public class LLexer {
    
    fileprivate let filePath: String
    fileprivate let fileSource: String
    
    fileprivate var curIdx: String.Index
    
    public init(_ file: String) {
        filePath = file
        
        do {
            fileSource = try String(contentsOfFile: file, encoding: .utf8).rmComments
        } catch {
            fileSource = ""
        }
        curIdx = fileSource.startIndex
    }
}
```

我们使用的分析器是使用的是 LL(1)，也就是最做推导，自顶向下

在初始化一个lexer的时候，会传入文件的路径，通过 String(contentsOfFile) 的方法解析出全部的Token

#### 定义Parser

一个最简单的Parser只需要解析出某个指定的Token，为了通用，可以定义出一下的Parser

```swift
/// Parser
public struct Parser<Output, Input: Sequence> {
    
    public var parse: (Input) -> Result<(Output, Input), Error>
    
    public func run(_ input: Input) -> Output? {
        switch parse(input) {
        case .success(let (output, _)):
            #if DEBUG
            print("Parse Success: \(output)")
            #endif
            return output
        case .failure(let error):
            #if DEBUG
            print("Parse Failed: \(error)")
            #endif
            return nil
        }
    }
}
```

对于每一个Parser，执行 parse 后会返回一个result，parse失败会返回 error，成功后会返回对应的值和剩余的序列

最终我们的目标是解析出 interface 和 implement ，所以接下来先定义好对应的数据结构

```swift
/// ObjC 成员属性
public struct ObjCProperty {
    /// 修饰符
    public var decorate: String
    /// 类型
    public var type: String
    /// 属性名称
    public var propertyName: String
}

/// ObjC 接口
public struct ObjCInterface {
    public var name: String
    public var superClass: String
    public var properties: [ObjCProperty] = []
}

/// ObjC 实现
public struct ObjCImplement {
    public var name = ""
    public var methods: [ObjCMethod] = []
}

/// ObjC 方法
public struct ObjCMethod {
    /// 是否为静态方法
    public var statically = false
    /// 返回类型
    public var returnType = ""
    /// 参数列表
    public var params: [ObjCParam] = []
    /// 方法体中的方法调用
    public var invokes: [ObjCInvoke] = []
}

/// ObjC 方法参数
public struct ObjCParam {
    /// 参数名
    public var name: String
    /// 参数类型
    public var type: String
    /// 形参名
    public var formalName: String
}

/// 方法调用者
public indirect enum ObjCInvoker {
    case variable(String)
    case otherInvoke(ObjCInvoke)
}

/// 方法调用的参数
public struct ObjCInvokeParam {
    /// 参数名
    public var name: String
    /// 参数中的其他方法调用
    public var invokes: [ObjCInvoke]
}

/// 方法调用
public struct ObjCInvoke {
    public var invoker: ObjCInvoker
    public var params: [ObjCInvokeParam]
}

```

接下来先使用别名来定义用来解析Token的Parser

```swift
public typealias TokenParser<T> = Parser<T, [Token]>
```

定义一个方法用来返回解析单个Token的Parser

```swift
public func parser_token(_ type: TokenType) -> TokenParser<Token> {
    return TokenParser(parse: { (tks) -> Result<(Token, [Token]), Error> in
        guard let token = tks.first, token.type == type else {
            return .failure(ParseError.notMatch)
        }
        return .success((token, Array(tks.dropFirst())))
    })
}
```

写完了单个Token的解析以后我们需要的就是组合不同的Parser用来构建出最终的结果了，

#### 组合

在有了基本的解析器后我们就只需要考虑组合的问题了

以interface的Parser为例，要解析出一个Interface，首先我们肯定会遇到的第一个Token一定是 @interface，最后是@end符号，@interface 后面紧跟着的就是接口的类名，接下来如果有继承的话会在 `:`后面跟着父类的类名，中间会包含成员属性的定义和方法的定义，这里面我们不关心方法的定义，只关注 类，父类和成员属性

接下来我们要借助于柯里化的方法以及添加一些自定义的中缀运算符来构建InterfaceParser

```swift
/// parser for ObjCInterface
public var parser_OCInterface: TokenParser<ObjCInterface> {
    
    return curry(ObjCInterface.init)
        <^> p_ocinterface *> p_name => string
        <*> p_colon *> p_name  => string
        <*> tokens(until: p_ocEnd).map{
            parser_OCProperty.repeats.run($0) ?? []
    }
}
```

其中，p_ocinterface，p_name，p_colon 为基于单个Token的Parser 

```swift
/// @interface
var p_ocinterface: TokenParser<Token> {
    return parser_token(.atInterface)
}

/// *
var p_name: TokenParser<Token> {
    return parser_token(.name)
}

/// :
var p_colon: TokenParser<Token> {
    return parser_token(.colon)
}
```

其中 **curry(ObjCInterface.init)** 是对 ObjCInterface 的初始化方法进行柯里化，方便我们将Parser组合应用于初始化 ObjCInterface，下面的运算符定义是这样的

```swift
/// Map
func <^> <T, U, S> (f: @escaping (T) -> U, c: Parser<T, S>) -> Parser<U, S> {
    return c.map(f)
}

/// apply
func <*> <T, U, S> (l: Parser<(T) -> U, S>, r: Parser<T, S>) -> Parser<U, S> {
    return r.apply(l)
}

func => <T, U> (p: Parser<T, [Token]>, f: @escaping (T) -> U) -> Parser<U, [Token]> {
    return p.map(f)
}

extension Parser {
    
    func map<U>(_ f: @escaping (Output) -> U) -> Parser<U, Input> {
        return Parser<U, Input>(parse: { (input) -> Result<(U, Input), Error> in
            switch self.parse(input) {
            case .success(let (result, rest)):
                return .success((f(result), rest))
            case .failure(let error):
                return .failure(error)
            }
        })
    }
    
    func apply<U>(_ parser: Parser<(Output) -> U, Input>) -> Parser<U, Input> {
        return Parser<U, Input>(parse: { (input) -> Result<(U, Input), Error> in
            let lResult = parser.parse(input)
            guard let l = lResult.value else {
                return .failure(lResult.error ?? ParseError.unknow)
            }
            let rResult = self.parse(l.1)
            guard let r = rResult.value else {
                return .failure(rResult.error ?? ParseError.unknow)
            }
            return .success((l.0(r.0), r.1))
        })
    }
    
    func or(_ parser: Parser<Output, Input>) -> Parser<Output, Input> {
        return Parser<Output, Input>(parse: { (input) -> Result<(Output, Input), Error> in
            let result = self.parse(input)
            switch result {
            case .success(_):
                return result
            case .failure(_):
                return parser.parse(input)
            }
        })
    }
    
    func rightSequence<U>(_ parser: Parser<U, Input> ) -> Parser<U, Input> {
        return Parser<U, Input>(parse: { (input) -> Result<(U, Input), Error> in
            let lResult = self.parse(input)
            guard let l = lResult.value else {
                return .failure(lResult.error ?? ParseError.unknow)
            }
            let rResult = parser.parse(l.1)
            guard let r = rResult.value else {
                return .failure(rResult.error ?? ParseError.unknow)
            }
            return .success(r)
        })
    }
}

```

最终，将能够解析符合规则的一些的Interface，同理，我们也对 implement 进行一些组合，在对目标文件夹进行解析，就可以拿到所有的 invoker 。

#### 最后

还有一些问题没有得到解决，关于反射的问题暂时无法处理，这些字符串有的是写在代码里面，有的是写在plist等文件里面的，有兴趣的同学欢迎提供思路

https://www.jianshu.com/p/fa3568087881
https://github.com/thoughtbot/Runes
https://github.com/thoughtbot/curry