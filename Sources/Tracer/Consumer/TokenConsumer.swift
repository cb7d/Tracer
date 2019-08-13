//
//  TokenConsumer.swift
//  Tracer
//
//  Created by Felix on 2019/7/7.
//

import Foundation
import Curry
import LLexer


/// 传入 Token 返回结果为 T 的消费者
typealias TokenConsumer<T> = Consumer<T, [Token]>

extension Consumer where Input == [Token] {
    
    /// 转换消费者，将会对传入Token序列进行逐词解析
    var keepGoing: TokenConsumer<[Result]> {
        return TokenConsumer<[Result]> {
            (tokens) -> ConsumeResult<([Result], [Token])> in
            var result = [Result]()
            var list = tokens
            while list.count > 0 {
                switch self.consume(list) {
                case .success(let (token, rest)):
                    result.append(token)
                    list = rest
                case .failure(_):
                    list = Array(list.dropFirst())
                    continue
                }
            }
            return .success((result, list))
        }
    }
}

/// 任意Token
var anyToken: TokenConsumer<Token> {
    return Consumer(consume: { (input) -> ConsumeResult<(Token, [Token])> in
        guard let result = input.first else {
            return .failure(.notFound)
        }
        return .success((result, Array(input.dropFirst())))
    })
}

/// 泛型
var genericType: TokenConsumer<String?> {
    return toString <^> t_name.between(left: t_less, right: t_greater).optional
}

/// token转为字符串
var toString: (Token?) -> String {
    return { token in
        guard let token = token else { return "" }
        return token.text
    }
}

/// token转为字符串
var filterNameToString: ([Token]) -> [String] {
    return { tokens in
        return tokens.filter{return $0.type == .name}.map{return $0.text}
    }
}

/// 将token序列的字符拼接为字符串
func joinedBy(separator: String) -> ([Token]) -> String {
    return { tokens in
        return tokens.map { $0.text } .joined(separator: separator)
    }
}

func lazy<T>(_ consumer: @autoclosure @escaping () -> TokenConsumer<T>) -> TokenConsumer<T> {
    
    return TokenConsumer<T> { consumer().consume($0) }
}

func anyTokens(until consumer: TokenConsumer<Token>) -> TokenConsumer<[Token]> {
    return (consumer.opposite() *> anyToken).many()
}

func anyTokens(enclosedBy lc: TokenConsumer<Token>, rc: TokenConsumer<Token>) -> TokenConsumer<[Token]> {
    
    let content = lc.lookAhead() *> lazy(anyTokens(enclosedBy: lc, rc: rc))
        <|> ({ [$0] } <^> (rc.opposite() *> anyToken))
    
    return curry({ [$0] + Array($1.joined()) + [$2] }) <^> lc <*> content.many() <*> rc
}

func anyTokens(inside lc:TokenConsumer<Token>, rc: TokenConsumer<Token>) -> TokenConsumer<[Token]> {
    return anyTokens(enclosedBy: lc, rc: rc).map {
        Array($0.dropFirst().dropLast())
    }
}

var anyEnclosedTokens: TokenConsumer<[Token]> {
    return anyTokens(enclosedBy: t_openBrace, rc: t_closeBrace)
        <|> anyTokens(enclosedBy: t_openBracket, rc: t_closeBracket)
        <|> anyTokens(enclosedBy: t_openParen, rc: t_closeParen)
        <|> anyTokens(enclosedBy: t_less, rc: t_greater)
}

func anyOpenTokens(until p: TokenConsumer<Token>) -> TokenConsumer<[Token]> {
    return {$0.flatMap{$0}}
        <^> (p.opposite()
        *> (anyEnclosedTokens
        <|> anyToken.map {[$0]})).many()
}

func singleToken(_ type:TokenType) -> TokenConsumer<Token> {
    return TokenConsumer(consume: { (tokens) -> ConsumeResult<(Token, [Token])> in
        guard let token = tokens.first, token.type == type else {
            return .failure(.notFound)
        }
        return .success((token, Array(tokens.dropFirst())))
    })
}

func pure<T>(_ t:T) -> TokenConsumer<T> {
    return TokenConsumer<T>.result(t)
}


extension Consumer {
    
    func lookAhead() -> Consumer<Result, Input> {
        return Consumer<Result, Input>(consume: { (input) -> ConsumeResult<(Result, Input)> in
            switch self.consume(input) {
            case .success(let (result, _)):
                return .success((result, input))
            case .failure(let error):
                return .failure(error)
            }
        })
    }
    
    func or(_ consumer: Consumer<Result, Input>) -> Consumer<Result, Input> {
        return  Consumer<Result, Input>(consume: { (input) -> ConsumeResult<(Result, Input)> in
            let res = self.consume(input)
            switch res {
            case .success(_):
                return res
            case .failure(_):
                return consumer.consume(input)
            }
        })
    }
    
    // 将f应用于Consumer的返回值
    func map<U>(_ f: @escaping (Result) -> U) -> Consumer<U, Input> {
        return Consumer<U, Input>(consume: { (input) -> ConsumeResult<(U, Input)> in
            switch self.consume(input) {
            case .success(let (result, rest)):
                return .success((f(result), rest))
            case .failure(let error):
                return .failure(error)
            }
        })
    }
    
    func flatMap<U>(_ f: @escaping (Result) -> Consumer<U, Input>) -> Consumer<U, Input> {
        return Consumer<U, Input>(consume: { (input) -> ConsumeResult<(U, Input)> in
            switch self.consume(input) {
            case .success(let (result, rest)):
                let c = f(result)
                return c.consume(rest)
            case .failure(let error):
                return .failure(error)
            }
        })
    }
    
    func apply<U>(_ consumer: Consumer<(Result) -> U, Input>) -> Consumer<U, Input> {
        return Consumer<U, Input>(consume: { (input) -> ConsumeResult<(U, Input)> in
            let lcResult = consumer.consume(input)
            guard let l = lcResult.value else {
                return .failure(lcResult.error ?? .unKnown)
            }
            let rcResult = self.consume(l.1)
            guard let r = rcResult.value else {
                return .failure(rcResult.error ?? .unKnown)
            }
            return .success((l.0(r.0), r.1))
        })
    }
    
    func opposite() -> Consumer<Result?, Input> {
        return Consumer<Result?, Input>(consume: { (input) -> ConsumeResult<(Result?, Input)> in
            switch self.consume(input){
            case .success((_, _)):
                return .failure(.unKnown)
            case .failure(_):
                return .success((nil, input))
            }
        })
    }
    
    func notFollowedBy<U>(_ c: Consumer<U, Input>) -> Consumer<Result, Input> {
        return self <* c.opposite()
    }
    
    func many() -> Consumer<[Result], Input> {
        return Consumer<[Result], Input>(consume: { (input) -> ConsumeResult<([Result], Input)> in
            var results = [Result]()
            var rest = input
            while true {
                switch self.consume(rest) {
                case .success(let (result, left)):
                    results.append(result)
                    rest = left
                case .failure(_):
                    return .success((results.compactMap{ $0 }, rest))
                }
            }
        })
    }
    
    func manyLeast1() -> Consumer<[Result], Input> {
        return Consumer<[Result], Input>(consume: { (input) -> ConsumeResult<([Result], Input)> in
            var results = [Result]()
            var rest = input
            while true {
                switch self.consume(rest) {
                case .success(let (result, left)):
                    results.append(result)
                    rest = left
                case .failure(let error):
                    if results.count == 0 {
                        return .failure(error)
                    }else {
                        return .success((results.compactMap{ $0 }, rest))
                    }
                }
            }
        })
    }
    
    func between<L, R>(left: Consumer<L, Input>, right: Consumer<R, Input>) -> Consumer<Result, Input> {
        return left *> self <* right
    }
    
    func separated<U>(atLeastOneby separator: Consumer<U, Input>) -> Consumer<[Result], Input> {
        return self.flatMap({ (result) -> Consumer<[Result], Input> in
            return (separator *> self)
                .many()
                .notFollowedBy(separator)
                .flatMap({ (input) -> Consumer<[Result], Input> in
                    return .result([result] + input)
                })
        })
    }
    
    func separated<U>(by separator: Consumer<U, Input>) -> Consumer<[Result], Input> {
        return Consumer<[Result], Input>(consume: { (input) -> ConsumeResult<([Result], Input)> in
            guard case let .success((result, rest)) = self.consume(input) else {
                return .success(([], input))
            }
            
            let restConsumer = (separator *> self).many().notFollowedBy(separator)
            
            switch restConsumer.consume(rest) {
            case .success(let (tks, left)):
                let results = [result] + tks
                return .success((results.compactMap{$0}, left))
            case .failure(let error):
                return .failure(error)
            }
        })
    }
}

// <^>
// 返回结果经过左侧函数加工的消费者
func <^> <T, U, S> (f: @escaping (T) -> U, c: Consumer<T, S>) -> Consumer<U, S> {
    return c.map(f)
}

// <*>
// 返回结果经过左侧函数加工的消费者
func <*> <T, U, S> (lc: Consumer<(T) -> U, S>, rc: Consumer<T, S>) -> Consumer<U, S> {
    return rc.apply(lc)
}

func <|> <T, S> (lc: Consumer<T, S>, rc: Consumer<T, S>) -> Consumer<T, S> {
    return lc.or(rc)
}

// *>
// 顺序执行，成功后右侧的Consumer返回
func *> <T, U, S>(lc: Consumer<T, S>, rc: Consumer<U, S>) -> Consumer<U, S> {
    return Consumer<U, S>(consume: { (input) -> ConsumeResult<(U, S)> in
        let lcResult = lc.consume(input)
        guard let l = lcResult.value else {
            return .failure(lcResult.error ?? ConsumeError.unKnown)
        }
        let rcResult = rc.consume(l.1)
        guard let r = rcResult.value else {
            return .failure(rcResult.error ?? ConsumeError.unKnown)
        }
        return .success(r)
    })
}

// <*
// 顺序执行，成功后左侧的Consumer返回
func <* <T, U, S>(lc: Consumer<T, S>, rc: Consumer<U, S>) -> Consumer<T, S> {
    return Consumer<T, S>(consume: { (input) -> ConsumeResult<(T, S)> in
        let lcResult = lc.consume(input)
        guard let l = lcResult.value else {
            return .failure(lcResult.error ?? ConsumeError.unKnown)
        }
        let rcResult = rc.consume(l.1)
        guard let r = rcResult.value else {
            return .failure(rcResult.error ?? ConsumeError.unKnown)
        }
        return .success((l.0, r.1))
    })
}

// =>
// 转换Consumer类型
func => <T, U> (consumer: Consumer<T, [Token]>, f: @escaping (T) -> U) -> Consumer<U, [Token]> {
    return consumer.map(f)
}

func => <T, U> (consumer: Consumer<[T]?, [Token]>, f: @escaping (T) -> U) -> Consumer<[U], [Token]> {
    return consumer.map({ (list) in
        if let list = list {
            return list.map{f($0)}
        }else {
            return []
        }
    })
}

precedencegroup MonadicPrecedenceRight {
    associativity: right
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: AssignmentPrecedence
}

precedencegroup MonadicPrecedenceLeft {
    associativity: left
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: AssignmentPrecedence
}

precedencegroup ErrorMessagePrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
    lowerThan: ComparisonPrecedence
}

precedencegroup AlternativePrecedence {
    associativity: left
    higherThan: ErrorMessagePrecedence
    lowerThan: NilCoalescingPrecedence
}

precedencegroup BetweenAlternativeAndApplicative {
    associativity: left
    higherThan: AlternativePrecedence
    lowerThan: NilCoalescingPrecedence
}

precedencegroup ApplicativePrecedence {
    associativity: left
    higherThan: BetweenAlternativeAndApplicative
    lowerThan: NilCoalescingPrecedence
}

precedencegroup BetweenApplicativeAndSequence {
    associativity: left
    higherThan: ApplicativePrecedence
    lowerThan: NilCoalescingPrecedence
}

precedencegroup ApplicativeSequencePrecedence {
    associativity: left
    higherThan: BetweenApplicativeAndSequence
    lowerThan: NilCoalescingPrecedence
}

/**
 map a function over a value with context
 
 Expected function type: `(a -> b) -> f a -> f b`
 */
infix operator <^> : ApplicativePrecedence

/**
 apply a function with context to a value with context
 
 Expected function type: `f (a -> b) -> f a -> f b`
 */
infix operator <*> : ApplicativePrecedence

/**
 sequence actions, discarding right (value of the second argument)
 
 Expected function type: `f a -> f b -> f a`
 */
infix operator <* : ApplicativeSequencePrecedence

/**
 sequence actions, discarding left (value of the first argument)
 
 Expected function type: `f a -> f b -> f b`
 */
infix operator *> : ApplicativeSequencePrecedence

/**
 an associative binary operation
 
 Expected function type: `f a -> f a -> f a`
 */
infix operator <|> : AlternativePrecedence

/**
 map a function over a value with context and flatten the result
 
 Expected function type: `m a -> (a -> m b) -> m b`
 */
infix operator >>- : MonadicPrecedenceLeft

/**
 map a function over a value with context and flatten the result
 
 Expected function type: `(a -> m b) -> m a -> m b`
 */
infix operator -<< : MonadicPrecedenceRight

/**
 return specified message while the fail
 */
infix operator <?> : ErrorMessagePrecedence

infix operator => : BetweenApplicativeAndSequence

infix operator <⊙> : BetweenApplicativeAndSequence

infix operator <△> : BetweenApplicativeAndSequence

infix operator <→> : BetweenApplicativeAndSequence

infix operator <->> : BetweenApplicativeAndSequence
