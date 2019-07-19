//
//  String+Extension.swift
//  Tracer
//
//  Created by Felix on 2019/7/15.
//

import Foundation

extension String {
    
    /// 注释类型
    var commentsStyles: [String] {
        return ["//.*?\\n", "/\\*[\\s\\S]*?\\*/"]
    }
    
    /// 将所有注释去除
    var withOutComments: String {
        var result = self
        commentsStyles.forEach{
            do {
                let regex = try NSRegularExpression(pattern: $0, options: NSRegularExpression.Options(rawValue: 0))
                result = regex.stringByReplacingMatches(in: result, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: result.count), withTemplate: "")
            }catch {
                #if DEBUG
                print(error)
                #endif
            }
        }
        return result
    }
}
