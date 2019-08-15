//
//  Tracer.swift
//  Tracer
//
//  Created by Felix on 2019/7/4.
//

import Foundation
import LLexer
import Parser

fileprivate let maxConcurrent: Int = 4

class Tracer {
    
    let filePath: Path
    
    fileprivate let semaphore = DispatchSemaphore(value: maxConcurrent)
    
    required init(_ path: String) {
        filePath = Path(path)
    }
    
    func run() {
        
        
        
        //        var classes = Set<String>()
        //        var invokers = Set<String>()
        
        let paths = filePath.files().filter{ $0.fileIsObjC() }.map{ $0.stringValue() }
        paths.forEach{ p in
            
            //            semaphore.wait()
            //
            //            DispatchQueue.global().async {
            //
            //
            //
            //                self.semaphore.signal()
            //            }
            
            
            let tokens = LLexer(p).tokens
            
//            if let nodes = parser_OCInterface.run(tokens) {
//
//                print("Interfaces")
//                print(nodes)
//
//            }
//
//            if let nodes = parser_OCImplement.run(tokens) {
//
//                print("Implement")
//                print(nodes)
//
//            }
            
            if let nodes = parser_OCMethodDefine.repeats.run(tokens) {
                
                print("Methods")
                print(nodes)
                
            }
            
            
            
            
            //            return
            
            //            if let interfaces = ObjCInterfaceConsumer.run(tokens) {
            //                interfaces.forEach{
            //                    classes.insert($0.className)
            //                    //                        if let superClassName = $0.superClass {
            //                    //                            classes.insert(superClassName)
            //                    //                        }
            //                }
            //            }
            
            
            
            //            if let tks = ObjCFuncDefineConsumer.run(tokens) {
            //
            //
            //                tks.forEach{funcNode in
            //                    funcNode.invokes.forEach{invoke in
            //
            //                        var wait = true
            //                        var invoker = invoke.invoker
            //                        while wait {
            //                            switch invoker {
            //                            case .variable(let name):
            //                                invokers.insert(name)
            //                                wait = false
            //                            case .invokeNode(let node):
            //                                invoker = node.invoker
            //                            }
            //                        }
            //                    }
            //                }
            //            }
            
            
        }
        
        //        waitUntilFinished()
        
        //        let uselessClass = classes.filter{!invokers.contains($0)}
        //        print(uselessClass.sorted())
        
        
    }
}

extension Tracer {
    
    private func waitUntilFinished() {
        for _ in 0..<maxConcurrent {
            semaphore.wait()
        }
        for _ in 0..<maxConcurrent {
            semaphore.signal()
        }
    }
}
