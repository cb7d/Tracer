//
//  Token.swift
//  Tracer
//
//  Created by Felix on 2019/7/4.
//

import Foundation


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
/// - atEnd: @end
/// - atImport: @import
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
enum TokenType {
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
    case atEnd
    case atImport
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


struct Token {
    let type: TokenType
    let detail: String
}

extension Token: CustomStringConvertible {
    
    var description: String {
        return "\(self.detail)"
    }
}
