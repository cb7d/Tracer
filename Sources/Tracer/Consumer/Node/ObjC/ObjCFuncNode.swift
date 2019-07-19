//
//  ObjCMethodNode.swift
//  Tracer
//
//  Created by Felix on 2019/7/6.
//

import Foundation

//struct ObjCInvoker: Node {
//    var name = ""
//    var otherInvoke: ObjCInvokeNode
//}

struct ObjCInvokeNode: Node {
    //    var invoker = ""
    //    var method = ""
    var des = ""
}


/// ObjC 方法节点
struct ObjCFuncNode: Node {
    /// 方法是否为静态类型
    var funcIsStatic = false
    /// 返回值描述
    var returnType = ""
    /// 方法名称
    var funcName = ""
    /// 参数列表
    var params: [ObjCParamNode] = []
    
    var invokes: [ObjCInvokeNode] = []
}

extension ObjCFuncNode: CustomStringConvertible {
    
    var description: String {
        let type = funcIsStatic ? "+" : "-"
        let name = (funcName.count > 0) ? funcName : (params.map{$0.description}.joined(separator: " "))
        var str = "\(type) (\(returnType))\(name)"
        if invokes.count == 0 {
            return str
        }
        str = str + invokes.reduce("{", {
            $0 + "\n" + "   " + "[" + $1.des + "]"
        })
        return str + "}"
    }
}

// - (void)speak;
// - (void)speak {}
// - (void)speak:(NSString *)word;
// - (void)speak:(NSString *)word {}
