//
//  ObjCConsumers.swift
//  Tracer
//
//  Created by Felix on 2019/7/14.
//

import Foundation
import Curry
import LLexer


/// ObjC 方法是否为类方法
var ObjCFuncIsStaticConsumer: TokenConsumer<Bool> {
    return t_minus
        *> pure(false)
        <|> t_plus
        *> pure(true)
}

/// ObjC 方法返回值类型
var ObjCFuncReturnsConsumer: TokenConsumer<String> {
    return anyTokens(inside: t_openParen, rc: t_closeParen) => joinedBy(separator: " ")
}

/// ObjC 协议
var ObjCProtocolConsumer :TokenConsumer<[ObjCProtocolNode]> {
    return (curry(ObjCProtocolNode.init)
        <^> t_atProtocol
        *> t_name
        => toString).keepGoing
}

/// ObjC 接口
var ObjCInterfaceConsumer: TokenConsumer<[ObjCInterfaceNode]> {
    
    let consumer = curry(ObjCInterfaceNode.init)
        <^> t_interface *> t_name => toString
        <*> (t_colon *> t_name).optional => toString
        <*> t_name.between(left: t_openParen, right: t_closeParen).optional => toString
        <*> (t_name.separated(by: t_comma).between(left: t_less, right: t_greater)).optional => toString
        <*> anyTokens(until: t_end).map{
            ObjCFuncDeclConsumer.run($0) ?? []
    }
    return consumer.keepGoing
}

/// 参数列表解析
var ObjCFuncParamListConsumer: TokenConsumer<[ObjCParamNode]> {
    
    let consumer = curry(ObjCParamNode.init)
        <^> t_name <* t_colon => toString
        <*> ObjCFuncReturnsConsumer
        <*> t_name => toString
    return consumer.manyLeast1()
}

var ObjCMethodSelector: TokenConsumer<[ObjCParamNode]> {
    return ObjCFuncParamListConsumer <|> curry({ [ObjCParamNode(name: $0.text, type: "", formalname: "")] }) <^> t_name
}

/// 单个方法定义解析
var ObjCSingleFuncDeclConsumer: TokenConsumer<ObjCFuncNode> {
    
    /// 尝试无参函数解析
//    let consumer1 =  curry(ObjCFuncNode.init)
//        <^> ObjCFuncIsStaticConsumer
//        <*> ObjCFuncReturnsConsumer
//        <*> t_name <* t_semicolon => toString
//        <*> pure([])
//        <*> pure([])
//
//    /// 尝试有参函数解析
//    let consumer =  curry(ObjCFuncNode.init)
//        <^> ObjCFuncIsStaticConsumer
//        <*> ObjCFuncReturnsConsumer
//        <*> pure("")
//        <*> ObjCFuncParamListConsumer <* t_name.optional <* t_semicolon
//        <*> pure([])
//
//    return (consumer1 <|> consumer)
    
    
    
    let consumer =  curry(ObjCFuncNode.init)
        <^> ObjCFuncIsStaticConsumer
        <*> ObjCFuncReturnsConsumer
        <*> pure("")
        <*> ObjCMethodSelector <* t_name.optional <* t_semicolon
        <*> pure([])
    
    return consumer
}

/// ObjC 方法定义
var ObjCFuncDeclConsumer: TokenConsumer<[ObjCFuncNode]> {
    
    return ObjCSingleFuncDeclConsumer.keepGoing
}

/// ObjC 方法实现
var ObjCFuncDefineConsumer: TokenConsumer<[ObjCFuncNode]> {
    
    var body: TokenConsumer<[Token]> {
        return anyTokens(inside: t_openBrace, rc: t_closeBrace)
    }
    
    let consumer =  curry(ObjCFuncNode.init)
        <^> ObjCFuncIsStaticConsumer
        <*> ObjCFuncReturnsConsumer
        <*> pure("")
        <*> ObjCMethodSelector
        <*> ({
            print("parse define with \($0)")
            return ObjCInvokeConsumer.run($0) ?? [] } <^> body )
    
    return consumer.keepGoing
}


/// ObjC 方法调用
var ObjCInvokeConsumer: TokenConsumer<[ObjCInvokeNode]> {
    
    return ObjCMsgSendConsumer.keepGoing.map({ (invokes) -> [ObjCInvokeNode] in
        var res = invokes
        invokes.forEach{invoke in
            res.append(contentsOf: invoke.params.reduce([]) { $0 + $1.invokes })
        }
        return res
    });
}

/// 单条方法调用
var ObjCMsgSendConsumer: TokenConsumer<ObjCInvokeNode> {
    let msg = curry(ObjCInvokeNode.init)
        <^> ObjCInvokerConsumer
        <*> ObjCInvokeParamConsumer;
    
    return msg.between(left: t_openBracket, right: t_closeBracket)
}


/// ObjC 方法调用中的调用者
var ObjCInvokerConsumer: TokenConsumer<ObjCInvoker> {
//    return TokenConsumer<ObjCInvoker>(consume: { (tokens) -> ConsumeResult<(ObjCInvoker, [Token])> in
//        return .failure(.notCase)
//    })
    
    let toMethodInvoker:(ObjCInvokeNode) -> ObjCInvoker = { invoke in
        .invokeNode(invoke)
    }
    
    let toMethodVariable:(Token) -> ObjCInvoker = { token in
        .variable(token.text)
    }
    
    return lazy(ObjCMsgSendConsumer) => toMethodInvoker
        <|> t_name => toMethodVariable
}

/// ObjC 方法调用参数列表
var ObjCInvokeParamConsumer: TokenConsumer<[ObjCInvokeParam]> {
    
    var paramBody: TokenConsumer<[ObjCInvokeNode]> {
        return { lazy(ObjCMsgSendConsumer).keepGoing.run($0) ?? [] }
            <^> anyOpenTokens(until: t_closeBracket <|> t_name *> t_colon)
    }
    
    var param: TokenConsumer<ObjCInvokeParam> {
        return curry(ObjCInvokeParam.init)
            <^> (curry({ "\($0.text)\($1.text)" }) <^> t_name <*> t_colon )
            <*> paramBody
    }
    
    var paramList: TokenConsumer<[ObjCInvokeParam]> {
        return param.manyLeast1()
    }
    
    var paramSelector: TokenConsumer<[ObjCInvokeParam]> {
        return paramList <|> {[ObjCInvokeParam(name: $0.text, invokes: [])]} <^> t_name
    }
    
    return paramSelector
//    return TokenConsumer<[ObjCInvokeParam]>(consume: { (tokens) -> ConsumeResult<([ObjCInvokeParam], [Token])> in
//        return .failure(.notCase)
//    })
}


/// ObjC 实现
var ObjCImplementConsumer: TokenConsumer<[ObjCImplementNode]> {

    return (ObjCImplementNode.init
        <^> t_implement
        *> t_name
        => toString).keepGoing
}



// MARK: - Method

//func toMethodInvoker() -> (ObjCInvokeNode) -> ObjCInvoker {
//    return { invoke in
//        .invokeNode(invoke)
//    }
//}
//
//func toMethodInvoker() -> (Token) -> ObjCInvoker {
//    return { token in
//        .variable(token.detail)
//    }
//}
