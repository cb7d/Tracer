//
//  ObjCParamNode.swift
//  Tracer
//
//  Created by Felix on 2019/7/17.
//

import Foundation

struct ObjCParamNode: Node {
    /// 参数名
    var name: String
    /// 参数类型
    var type: String
    /// 形参名
    var formalname: String
}

//extension ObjCParamNode: CustomStringConvertible {
//    
//    var description: String {
//        return "\(name):(\(type))\(formalname)"
//    }
//}
