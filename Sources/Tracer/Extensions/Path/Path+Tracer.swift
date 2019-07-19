//
//  Path+Tracer.swift
//  Tracer
//
//  Created by Felix on 2019/7/5.
//

import Foundation

enum FileSourceType: String {
    case m
    case mm
    case h
    case swift
    case unKnow
}

extension Path {
    
    func sourceType() -> FileSourceType {
        switch  fileExtension(){
        case FileSourceType.m.rawValue:
            return FileSourceType.m
        case FileSourceType.mm.rawValue:
            return FileSourceType.mm
        case FileSourceType.h.rawValue:
            return FileSourceType.h
        case FileSourceType.swift.rawValue:
            return FileSourceType.swift
        default:
            return .unKnow
        }
    }
    
    func fileIsObjC() -> Bool {
        return sourceType() == .m || sourceType() == .mm || sourceType() == .h
    }
    
    func fileIsSwift() -> Bool {
        return sourceType() == .swift
    }
}
