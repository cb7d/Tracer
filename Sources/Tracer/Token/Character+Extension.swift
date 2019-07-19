//
//  Character+Extension.swift
//  Tracer
//
//  Created by Felix on 2019/7/15.
//

import Foundation

extension Character {
    
    /// 是否为字母
    var isLetter: Bool {
        return (self >= "a" && self <= "z") || (self >= "A" && self <= "Z")
    }
    
    /// 是否为数字
    var isNumber: Bool {
        return (self >= "0") && (self <= "9")
    }
}
