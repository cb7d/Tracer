//
//  ObjCNode.swift
//  Tracer
//
//  Created by Felix on 2019/7/6.
//

import Foundation

/// 对一次token序列消费的节点汇总
struct ObjCNode: Node {
    var interface: [ObjCInterfaceNode]?
    var implement: [ObjCImplementNode]?
    var ocProtocol: [ObjCProtocolNode]?
}

//let inter = ObjCInterfaceNode(className: "", superClass: "", categoryName: "", protocols: [])
