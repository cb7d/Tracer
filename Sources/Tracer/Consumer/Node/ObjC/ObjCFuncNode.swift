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

indirect enum ObjCInvoker: Node {
    case variable(String)
    case invokeNode(ObjCInvokeNode)
}

struct ObjCInvokeParam: Node {
    var name: String
    var invokes: [ObjCInvokeNode]
}

struct ObjCInvokeNode: Node {
//    var des = ""
//    var tokens: [String]
    var invoker: ObjCInvoker
    var params: [ObjCInvokeParam]
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


extension ObjCInvoker {
    enum CodingKeys: String, CodingKey {
        case key
        case variable
        case invoke
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .variable(let name):
            try container.encode("variable", forKey: .key)
            try container.encode(name, forKey: .variable)
        case .invokeNode(let node):
            try container.encode("invoke", forKey: .key)
            try container.encode(node, forKey: .invoke)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = try container.decode(String.self, forKey: .key)
        
        switch key {
        case "variable":
            self = .variable(
                try container.decode(String.self, forKey: .variable)
            )
        default:
            self = .invokeNode(
                try container.decode(ObjCInvokeNode.self, forKey: .invoke)
            )
        }
    }
}

//extension ObjCFuncNode: CustomStringConvertible {
//    
//    var description: String {
//        let type = funcIsStatic ? "+" : "-"
//        let name = (funcName.count > 0) ? funcName : (params.map{$0.description}.joined(separator: " "))
//        var str = "\(type) (\(returnType))\(name)"
//        if invokes.count == 0 {
//            return str
//        }
//        str = str + invokes.reduce("{", {
//            $0 + "\n" + "   " + "[" + $1.des + "]"
//        })
//        return str + "}"
//    }
//}

// - (void)speak;
// - (void)speak {}
// - (void)speak:(NSString *)word;
// - (void)speak:(NSString *)word {}
