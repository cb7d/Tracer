//
//  ObjCConsumers.swift
//  Tracer
//
//  Created by Felix on 2019/7/14.
//

import Foundation
import Curry



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
    return consumer.many()
}

/// 单个方法定义解析
var ObjCSingleFuncDeclConsumer: TokenConsumer<ObjCFuncNode> {
    
    /// 尝试无参函数解析
    let consumer1 =  curry(ObjCFuncNode.init)
        <^> ObjCFuncIsStaticConsumer
        <*> ObjCFuncReturnsConsumer
        <*> t_name <* t_semicolon => toString
        <*> pure([])
        <*> pure([])
    
    /// 尝试有参函数解析
    let consumer =  curry(ObjCFuncNode.init)
        <^> ObjCFuncIsStaticConsumer
        <*> ObjCFuncReturnsConsumer
        <*> pure("")
        <*> ObjCFuncParamListConsumer <* t_name.optional <* t_semicolon
        <*> pure([])
    
    return (consumer1 <|> consumer)
}

/// ObjC 方法定义
var ObjCFuncDeclConsumer: TokenConsumer<[ObjCFuncNode]> {
    
    return ObjCSingleFuncDeclConsumer.keepGoing
}

/// ObjC 方法实现
var ObjCFuncDefineConsumer: TokenConsumer<[ObjCFuncNode]> {
    
    /// 尝试无参函数解析
    let consumer1 =  curry(ObjCFuncNode.init)
        <^> ObjCFuncIsStaticConsumer
        <*> ObjCFuncReturnsConsumer
        <*> t_name <* t_openBrace => toString
        <*> pure([])
        <*> ObjCInvokeConsumer
    
    /// 尝试有参函数解析
    let consumer =  curry(ObjCFuncNode.init)
        <^> ObjCFuncIsStaticConsumer
        <*> ObjCFuncReturnsConsumer
        <*> pure("")
        <*> ObjCFuncParamListConsumer <* t_name.optional <* t_openBrace
        <*> ObjCInvokeConsumer
    
    return (consumer1 <|> consumer).keepGoing
}

var ObjCInvokeConsumer: TokenConsumer<[ObjCInvokeNode]> {
    
    let consumer = ObjCInvokeNode.init <^> anyTokens(inside: t_openBracket, rc: t_closeBracket) => joinedBy(separator: " ")
    return consumer.keepGoing
}


/// ObjC 实现
var ObjCImplementConsumer: TokenConsumer<[ObjCImplementNode]> {
    
    return (ObjCImplementNode.init
        <^> t_implement
        *> t_name
        => toString).keepGoing
}



