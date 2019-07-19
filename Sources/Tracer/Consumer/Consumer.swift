//
//  Parser.swift
//  Tracer
//
//  Created by Felix on 2019/7/4.
//

import Foundation


/// 消费者出现错误
///
/// - notFound: 未能匹配到Token
/// - unKnown: 未知错误
/// - notCase: 不关心的错误
/// - other: 其他自定义
enum ConsumeError: Error {
    case notFound
    case unKnown
    case notCase
    case other(String)
}

/// 消费者反馈结果
///
/// - success: 成功
/// - failure: 失败
enum ConsumeResult<T> {
    case success(T)
    case failure(ConsumeError)
}

// MARK: - 判断消费是否成功
extension ConsumeResult {
    
    /// 结果可选值
    var value: T? {
        switch self {
        case .success(let result):
            return result
        case .failure(_):
            return nil
        }
    }
    /// 错误可选值
    var error: ConsumeError? {
        switch self {
        case .success(_):
            return nil
        case .failure(let error):
            return error
        }
    }
}

/// 消费者结构体
struct Consumer<Result, Input: Sequence> {
    
    /// 初始化需传入（输入为序列，输入为结果和剩余序列的）函数
    var consume: (Input) -> ConsumeResult<(Result,Input)>
    
    
    /// 对指定序列进行消费
    func run(_ input: Input) -> Result? {
        switch consume(input) {
        case .success(let (res, _)):
            return res
        case .failure(let error):
            #if DEBUG
            print(error)
            #endif
            return nil
        }
    }
}

extension Consumer {
    
    /// 尝试传入序列，对剩余序列继续消费，不会报错，用于可选值类型的解析
    var optional: Consumer<Result?, Input> {
        return Consumer<Result?, Input>(consume: { (input) -> ConsumeResult<(Result?, Input)> in
            switch self.consume(input) {
            case .success(let (result, rest)):
                return .success((result, rest))
            case .failure(_):
                return .success((nil, input))
            }
        })
    }
    
    /// 不消费，并且总是返回成功的结果
    static func result(_ r: Result) -> Consumer<Result, Input> {
        return Consumer(consume: { (input) -> ConsumeResult<(Result, Input)> in
            return .success((r, input))
        })
    }
}
