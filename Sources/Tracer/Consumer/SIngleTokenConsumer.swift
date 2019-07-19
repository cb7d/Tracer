//
//  SIngleTokenConsumer.swift
//  Tracer
//
//  Created by Felix on 2019/7/14.
//

import Foundation


/**
 所有仅消费单个Token的消费者
 */

var t_interface: TokenConsumer<Token> {
    return singleToken(.atInterface)
}

var t_implement: TokenConsumer<Token> {
    return singleToken(.atImplementation)
}

var t_name: TokenConsumer<Token> {
    return singleToken(.name)
}

var t_colon: TokenConsumer<Token> {
    return singleToken(.colon)
}

var t_semicolon: TokenConsumer<Token> {
    return singleToken(.semicolon)
}

var t_comma: TokenConsumer<Token> {
    return singleToken(.comma)
}

var t_minus: TokenConsumer<Token> {
    return singleToken(.minus)
}

var t_plus: TokenConsumer<Token> {
    return singleToken(.plus)
}

var t_openParen: TokenConsumer<Token> {
    return singleToken(.openParen)
}

var t_closeParen: TokenConsumer<Token> {
    return singleToken(.closeParen)
}

var t_openBrace: TokenConsumer<Token> {
    return singleToken(.openBrace)
}

var t_closeBrace: TokenConsumer<Token> {
    return singleToken(.closeBrace)
}

var t_openBracket: TokenConsumer<Token> {
    return singleToken(.openBracket)
}

var t_closeBracket: TokenConsumer<Token> {
    return singleToken(.closeBracket)
}

var t_less: TokenConsumer<Token> {
    return singleToken(.less)
}

var t_end: TokenConsumer<Token> {
    return singleToken(.atEnd)
}

var t_greater: TokenConsumer<Token> {
    return singleToken(.greater)
}


var t_atProtocol: TokenConsumer<Token> {
    return singleToken(.atProtocol)
}

