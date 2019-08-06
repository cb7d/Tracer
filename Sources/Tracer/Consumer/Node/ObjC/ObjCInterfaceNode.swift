//
//  InterfaceNode.swift
//  Tracer
//
//  Created by Felix on 2019/7/6.
//

import Foundation


/// ObjC 接口节点
struct ObjCInterfaceNode: Node {
    /// 类名
    var className = ""
    /// 父类名
    var superClass: String? = nil
    /// 分类名
    var categoryName: String? = nil
    
    var protocols: [String] = []
    
    var funcDecls: [ObjCFuncNode] = []
}

//extension ObjCInterfaceNode: CustomStringConvertible {
//    
//    var description: String {
//        return "@interface \(className)" + funcDecl.reduce("", {
//            return $0 + "\n" + $1.description
//        })
//    }
//}



//@interface TDFViewController : UIViewController
//
//@end


//@interface TDFViewController (TDFCommonHelper) <TDFVMDelegate, TDFListenerDelegate>
//
//@end

