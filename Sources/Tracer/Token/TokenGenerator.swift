//
//  TokenGenerator.swift
//  Tracer
//
//  Created by Felix on 2019/7/5.
//

import Foundation

enum TokenGenError: Error {
    case doesNotMatch
}

class TokenGen {
    
    let filePath: String
    let fileSource: String
    var fileIndex: String.Index
    
    required init(_ path: String) {
        filePath = path
        do {
            fileSource = try String(contentsOfFile: path, encoding: .utf8).withOutComments
        } catch {
            #if DEBUG
            print(error)
            #endif
            fileSource = ""
        }
        fileIndex = fileSource.startIndex
    }
    
    func tokens() -> [Token] {
        
        var tokens = [Token]()
        var token = getToken()
        
        while token.type != .EOF {
            tokens.append(token)
            token = getToken()
        }
        return tokens
    }
}

extension TokenGen {
    
    func getToken() -> Token {
        while !fileEnd {
            switch current {
            /// 换行、回车、制表符、空格全部丢弃
            case meaningless[0], meaningless[1], meaningless[2], meaningless[3]:
                skipMeaningless()
                continue
                
            case "+":
                gotoNext()
                return Token(type: .plus, detail: "+")
                
            case "-":
                gotoNext()
                if !fileEnd && current == ">" {
                    gotoNext()
                    return Token(type: .rightArrow, detail: "->")
                }
                return Token(type: .minus, detail: "-")
                
            case "*":
                gotoNext()
                return Token(type: .asterisk, detail: "*")
                
            case "\\":
                gotoNext()
                return Token(type: .backslash, detail: "\\")
                
            case "/":
                gotoNext()
                return Token(type: .forwardSlash, detail: "/")
                
            case "@":
                return atKey()
                
            case "#":
                return poundKey()
                
            case "$":
                gotoNext()
                return Token(type: .dollar, detail: "$")
                
            case "(":
                gotoNext()
                return Token(type: .openParen, detail: "(")
                
            case ")":
                gotoNext()
                return Token(type: .closeParen, detail: ")")
                
            case "[":
                gotoNext()
                return Token(type: .openBracket, detail: "[")
                
            case "]":
                gotoNext()
                return Token(type: .closeBracket, detail: "]")
                
            case "{":
                gotoNext()
                return Token(type: .openBrace, detail: "{")
                
            case "}":
                gotoNext()
                return Token(type: .closeBrace, detail: "}")
                
            case "<":
                gotoNext()
                return Token(type: .less, detail: "<")
                
            case ">":
                gotoNext()
                return Token(type: .greater, detail: ">")
                
            case ":":
                gotoNext()
                return Token(type: .colon, detail: ":")
                
            case ",":
                gotoNext()
                return Token(type: .comma, detail: ",")
                
            case ";":
                gotoNext()
                return Token(type: .semicolon, detail: ";")
                
                
            case "=":
                gotoNext()
                return Token(type: .equal, detail: "=")
                
            case "\"":
                gotoNext()
                return Token(type: .doubleQuotation, detail: "\"")
                
            case "^":
                gotoNext()
                return Token(type: .caret, detail: "^")
                
            case ".":
                gotoNext()
                return Token(type: .dot, detail: ".")
                
            default:
                
                if current.isLetter || current == "_" {
                    let v = variableName
                    switch variableName {
                    case "static":
                        return Token(type: .static, detail: "static")
                    case "return":
                        return Token(type: .return, detail: "return")
                    default:
                        break
                    }
                    return Token(type: .name, detail: v)
                }
                gotoNext()
                continue
            }
            
            
        }
        return Token(type: .EOF, detail: "")
    }
}

extension TokenGen {
    
    /// 文件已解析到末尾
    var fileEnd: Bool {
        return fileIndex == fileSource.endIndex
    }
    
    /// 换行、回车，制表
    var meaningless: [Character] {
        return ["\n", "\r", "\t", " "]
    }
    
    /// 当前字符
    var current: Character {
        return fileSource[fileIndex]
    }
    
    /// 进行下一个token的解析
    func gotoNext() {
        fileIndex = fileSource.index(after: fileIndex)
    }
    
    /// 以@开头的token解析
    func atKey() -> Token {
        
        if checkKeyWord(key: "@interface") {
            return Token(type: .atInterface, detail: "@interface")
        }else if checkKeyWord(key: "@implementation") {
            return Token(type: .atImplementation, detail: "@implementation")
        }else if checkKeyWord(key: "@protocol") {
            return Token(type: .atProtocol, detail: "@protocol")
        }else if checkKeyWord(key: "@end") {
            return Token(type: .atEnd, detail: "@end")
        }else if checkKeyWord(key: "@import") {
            return Token(type: .atImport, detail: "@import")
        }
        gotoNext()
        return Token(type: .at, detail: "@")
    }
    
    /// 以#开头的token解析
    func poundKey() -> Token {
        if checkKeyWord(key: "#import") {
            return Token(type: .poundImport, detail: "#import")
        }
        gotoNext()
        return Token(type: .pound, detail: "#")
    }
    
    /// 尝试匹配关键字
    func checkKeyWord(key: String) -> Bool {
        
        let curIdx = fileIndex
        do {
            try match(key)
            return true
        } catch {
            fileIndex = curIdx
            return false
        }
    }
    
    /// 匹配关键字
    func match(_ key: String) throws {
        var idx = key.startIndex
        
        while idx != key.endIndex && !fileEnd {
            if key[idx] != current {
                throw TokenGenError.doesNotMatch
            }
            idx = key.index(after: idx)
            gotoNext()
        }
        if idx != key.endIndex {
            throw TokenGenError.doesNotMatch
        }
    }
    
    /// 跳过无意义符号
    func skipMeaningless() {
        while !fileEnd && meaningless.contains(current) {
            gotoNext()
        }
    }
}

extension TokenGen {
    
    /// 解析变量名
    var variableName: String{
        guard !fileEnd else {
            return ""
        }
        
        var result = [Character]()
        var c: Character
        
        while !fileEnd {
            c = current
            if c.isLetter || c.isNumber || c == "_" {
                result.append(c)
                gotoNext()
            }else {
                break
            }
        }
        return String(result)
    }
}
