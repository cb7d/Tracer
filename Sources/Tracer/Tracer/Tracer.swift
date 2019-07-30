//
//  Tracer.swift
//  Tracer
//
//  Created by Felix on 2019/7/4.
//

import Foundation


class Tracer {
    
    let filePath: Path
    
    required init(_ path: String) {
        filePath = Path(path)
    }
    
    func run() {
        
        let paths = filePath.files().filter{ $0.fileIsObjC() }.map{ $0.stringValue() }
        _ = paths.map{
            let tokens = TokenGen($0).tokens()
            
            if let tks = ObjCInterfaceConsumer.run(tokens) {

                if tks.count > 0 {
                    print("Found Interfaces:")
                    print("=====================")
                    print(tks)
                }
            }
            
//            if let tks = ObjCFuncDefineConsumer.run(tokens) {
//
//                if tks.count > 0 {
//                    print("Found Define:")
//                    print("=====================")
//                    print(tks)
//                    
//                    tks.forEach{
//                        if $0.invokes.count > 0 {
//                            
//                        }
//                    }
//                }
//            }
            
            
//            if let nodes = ObjCFuncDeclConsumer.run(tokens) {
//                if nodes.count == 0 {
//                    return
//                }
//                print("=====================")
//                print("Parsing:\($0)")
//                print("=====================")
//                nodes.forEach {
//                    print($0)
//                }
//            }
            
//            if let nodes = ObjCFuncParamListConsumer.run(tokens) {
//
//                nodes.forEach {
//                    print($0)
//                }
//            }
            
//            if let nodes = ObjCImplementConsumer.run(tokens) {
//
//                nodes.forEach {
//                    print($0)
//                }
//            }
        }
    }
}
