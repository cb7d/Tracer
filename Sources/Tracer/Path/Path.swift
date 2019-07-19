//
//  Path.swift
//  Tracer
//
//  Created by Felix on 2019/7/4.
//

import Foundation


/// 路径类型
///
/// - file: 文件
/// - directory: 文件夹
/// - other: 其他
enum PathType {
    case file
    case directory
    case other
}

public struct Path {
    
    static let fm = FileManager.default
    static let separator = "/"
    
    let path: String
    
    init(_ pathString: String) {
        path = pathString
    }
}

extension Path {
    
    func files() -> [Path] {
        
        switch pathType() {
        case .other:
            return []
        case .file:
            return [self]
        case .directory:
            
            do {
                let result = try Path.fm.subpathsOfDirectory(atPath: path).map{
                        return Path(path + Path.separator + $0)
                    }.filter{
                        $0.pathType() == .file
                }
                return result
            }catch {
                return []
            }
        }
        
        
    }
    
    func exists() -> Bool {
        return Path.fm.fileExists(atPath: path)
    }
    
    func pathType() -> PathType {
        return path.pathType()
    }
    
    func stringValue() -> String {
        return path
    }
    
    func lastComponent() -> String {
        return path.lastComponent()
    }
    
    func fileExtension() -> String {
        return path.fileExtension()
    }
}

extension String {
    
    func pathType() -> PathType {
        var isdirectory = ObjCBool(false)
        let fileExist = Path.fm.fileExists(atPath: standardizingPath(), isDirectory: &isdirectory)
        if !fileExist {
            return .other
        }
        if isdirectory.boolValue {
            return .directory
        }
        return .file
    }
    
    func standardizingPath() -> String {
        return NSString(string: self).standardizingPath
    }
    
    func lastComponent() -> String {
        return NSString(string: self).lastPathComponent
    }
    
    func fileExtension() -> String {
        return NSString(string: self).pathExtension
    }
}

extension Path {
    
}
