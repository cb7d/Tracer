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

enum TracerTypeOption: String {
    case unused = "unused"
}

class Tracer {
    
    let filePath: Path
    
    let resultType: TracerTypeOption
    
    required init(_ path: String, type: TracerTypeOption) {
        filePath = Path(path)
        resultType = type
    }
    
    func allInvokes(_ invoke:ObjCInvoke) -> [ObjCInvoke] {
        var results = [ObjCInvoke]()
        results.append(invoke)
        
        if case .variable(_) = invoke.invoker {
            if invoke.params.count == 1 {
                if let invokeParam = invoke.params.last {
                    if invokeParam.invokes.count == 0 {
                        return results
                    }
                }
            }
        }
        
        if case .otherInvoke(let invoke2) = invoke.invoker {
            results.append(contentsOf: allInvokes(invoke2))
        }
        
        invoke.params.forEach { (invokeParam) in
            invokeParam.invokes.forEach({ (invoke2) in
                results.append(contentsOf: allInvokes(invoke2))
            })
        }
        
        return results
    }
    
    func invokerNames(_ invoke: ObjCInvoke) -> [String] {
        let invokes = allInvokes(invoke)
        return invokes.compactMap{
            if case .variable(let name) = $0.invoker {
                return name
            }
            return nil
        }
    }
    
    func run() {
        
        var ObjCImplements = [ObjCImplement]()
        var ObjCInterfaces = [ObjCInterface]()
        
        let paths = filePath.files().filter{ $0.fileIsObjC() }.map{ $0.stringValue() }
        paths.forEach{ p in
            
            print("Begin Parse::\(p)")
            let tokens = LLexer(p).tokens
            if let implements = parser_OCImplement.repeats.run(tokens) {
                ObjCImplements.append(contentsOf: implements)
            }
            
            if let interfaces = parser_OCInterface.repeats.run(tokens) {
                ObjCInterfaces.append(contentsOf: interfaces)
            }
            
        }
        
        if case .unused = self.resultType {
            
            self.findUnUsedClass(ObjCInterfaces, implements: ObjCImplements)
        }
    }
    
    func findUnUsedClass(_ interfaces: [ObjCInterface], implements: [ObjCImplement]) {
        
        var invokers = [String]()
        var classes = [String]()
        
        implements.forEach({ (impl) in
            classes.append(impl.name)
            impl.methods.forEach({ (method) in
                method.invokes.forEach({(invoke) in
                    let allinvokerNames = invokerNames(invoke)
                    invokers.append(contentsOf: allinvokerNames)
                })
            })
        })
        
        interfaces.forEach({ (interface) in
            interface.properties.forEach({ (property) in
                invokers.append(property.type)
            })
        })
        //        print("============")
        //        print(invokers)
        //        print("============")
        //        print(classes)
        //        print("============")
        
        let noUseClasses = classes.filter{!invokers.contains($0)}.sorted()
        //        .filter{!$0.hasSuffix("Cell")}
        print("UnusedClasses =>")
        print(noUseClasses)
        
        do {
            try noUseClasses.joined(separator: "\n").write(toFile: "./Tracer_UnusedClasses.txt", atomically: true, encoding: .utf8)
        }catch {
            print(error)
        }
    }
}
