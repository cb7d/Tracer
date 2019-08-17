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
    
    required init(_ path: String) {
        filePath = Path(path)
    }
    
    func run() {
        
        var invokers = [String]()
        var classes = [String]()
        
        func getFinalInvoker(_ invoker: ObjCInvoker) -> String {
            
            switch invoker {
            case .variable(let name):
                return name
            case .otherInvoke(let otherInvoke):
                return getFinalInvoker(otherInvoke.invoker)
            }
        }
        
        let paths = filePath.files().filter{ $0.fileIsObjC() }.map{ $0.stringValue() }
        paths.forEach{ p in
            
            let tokens = LLexer(p).tokens
            
            if let ocimplements = parser_OCImplement.repeats.run(tokens) {
                ocimplements.forEach({ (impl) in
                    classes.append(impl.name)
                    impl.methods.forEach({ (method) in
                        method.invokes.forEach({(invoke) in
                            let invoker = invoke.invoker
                            invokers.append(getFinalInvoker(invoker))
                        })
                    })
                })
            }
            if let interfaces = parser_OCInterfaces.run(tokens) {
                interfaces.forEach({ (interface) in
                    interface.properties.forEach({ (property) in
                        invokers.append(property.type)
                    })
                })
                
            }
            
        }
        print("============")
        print(invokers)
        print("============")
        print(classes)
        print("============")
        print(classes.filter{!invokers.contains($0)}.filter{!$0.hasSuffix("Cell")})
    }
}
